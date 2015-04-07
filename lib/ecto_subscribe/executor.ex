defmodule Ecto.Subscribe.Executor do
  import Ecto.Query
  import Ecto.Subscribe.Utils

  def execute(repo, changeset, model, action) do
    # execute a query by the primary key for the start
    query_result_key = query_model_from_system_key_tbl(repo, model)
    # find subscription returns the list of already sent notifications,
    # so we can pass it to the second query, to prevent duplication
    # of RPC calls, log output and etc... for the same subscription
    already_sent = find_subscription(query_result_key, changeset, model, action)    
    # now we can query main system table
    query_result = query_model_from_system_tbl(repo, model)
    find_subscription(query_result, changeset, model, action, already_sent)
  end

  defp find_subscription([], _, _, already_sent) do
    already_sent
  end

  defp find_subscription([subscription_row_in_db | subscription_in_db], changeset, model, action) do
    find_subscription(subscription_row_in_db, subscription_in_db, changeset, model, action, [])
  end

  defp find_subscription([], _changeset, _model, _ecto_event, already_sent) do
    already_sent
  end
  
  defp find_subscription([subscription_row_in_db | subscription_in_db], changeset, model, action, already_sent) do
    find_subscription(subscription_row_in_db, subscription_in_db, changeset, model, action, already_sent)
  end

  defp find_subscription(subscription_row_in_db, subscription_in_db, changeset, model, action, already_sent) do
    find_subscription_helper(subscription_row_in_db, subscription_in_db, changeset, model, action, already_sent)
  end
  
  defp find_subscription_helper(subscription_row_in_db, subscription_in_db, changeset, model, ecto_event, already_sent) do
    actions = string_to_actions(subscription_row_in_db.subscription_actions)
    case Enum.member?(actions, ecto_event) do
      true ->
        {field_name, operator, val} = db_row_to_map(subscription_row_in_db.subscription_info, model)
        changeset = update_changes_with_key(model, subscription_row_in_db, changeset)
        case validate_change(subscription_row_in_db, changeset, field_name, operator, val) do
          {:false, _} ->
            find_subscription(subscription_in_db, changeset, model, ecto_event, already_sent)
          {_, subscription_info} ->
            already_sent = call_adapter(subscription_info, changeset, ecto_event, already_sent)
            find_subscription(subscription_in_db, changeset, model, ecto_event, already_sent)
        end
      false ->
        is_subscription_for_all(actions, subscription_row_in_db, subscription_in_db, model, changeset, ecto_event, already_sent)
    end
  end

  def is_subscription_for_all([:all], subscription_info, subscription_in_db, model, changeset, ecto_event, already_sent) do
    already_sent = call_adapter(subscription_info, changeset, ecto_event, already_sent)
    find_subscription(subscription_in_db, changeset, model, ecto_event, already_sent)
  end

  def is_subscription_for_all(_, _subscription_info, subscription_in_db, model, changeset, ecto_event, already_sent) do
    find_subscription(subscription_in_db, changeset, model, ecto_event, already_sent)
  end

  def call_adapter(subscription_information, changeset, action, already_sent) do
    # before we've sent notification about event, we need to check that this event
    # can already be sent with the same provider
    {already_sent, is_already_sent} = is_already_sent(subscription_information, already_sent)
    case is_already_sent do
      true ->
        already_sent
      _ ->
        (subscription_information.adapter |> String.to_atom).send(subscription_information, changeset, action)
        already_sent
    end
  end

  defp is_already_sent(subscription_row_in_db, already_sent) do
    case subscription_row_in_db.adapter do
      "Elixir.Ecto.Subscribe.Adapter.Log" ->
        case List.keyfind(already_sent, :log, 0) do
          nil ->
            {[{:log, true} | already_sent], false}
          _ ->
            {already_sent, true}
        end
      "Elixir.Ecto.Subscribe.Adapter.Remove" ->
        case Enum.member(already_sent, {:node, subscription_row_in_db.receiver}) do
          false ->
            {[{:node, subscription_row_in_db.receiver} | already_sent], false}
          _ ->
            {already_sent, true}
        end
    end
  end

  defp query_model_from_system_tbl(repo, model) do
    model = Macro.to_string(model)
    repo.all(from q in Ecto.Subscribe.Schema.SystemTable, where: q.model == ^model)
  end
  
  defp query_model_from_system_key_tbl(repo, model) do
    key = get_primary_key_str(model)
    model = Macro.to_string(model)
    repo.all(from q in Ecto.Subscribe.Schema.SystemTable.Key, where: q.model == ^model and q.key == ^key)
  end

  def db_row_to_map(str, model) do
    [name, operator, val] = String.split(str, " ")
    map = Map.put_new(%{}, name, val)
    changeset = Ecto.Changeset.cast(model.__struct__, map, [], [name])
    {String.to_atom(name), operator, changeset.changes[name |> String.to_atom]}
  end

  def update_changes_with_key(model, query_result, changeset) do
    map = Map.from_struct(query_result)
    case map.__meta__.source do
      "ecto_subscribe_key" ->
        Map.put(changeset.changes, query_result.key |> String.to_atom, 
                map[get_primary_key_str(model) |> String.to_atom])
      _ ->
        changeset.changes
    end
  end

  defp validate_change(subscription_row_in_db, changes, field_name, operator, val) do
    case Map.get(changes, field_name, 0) do
      nil ->
        :false
      updated_val ->
        case operator do
          "==" ->
            {val == updated_val, subscription_row_in_db}
          ">" ->
            {updated_val > val, subscription_row_in_db}
          "<" ->
            {updated_val > val, subscription_row_in_db}
          _ ->
            {:false, []}
        end
    end
  end
end
