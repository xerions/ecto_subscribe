defmodule Ecto.Subscribe.Api do

  import Ecto.Query
  import Ecto.Model.Callbacks

  @doc """
  """
  def subscribe(repo, model) do
    repo.insert(%Ecto.Subscribe.Schema.SystemTable{model: (model |> Atom.to_string),
                                                   subscription_info: "all",
                                                   subscription_actions: "all"})
    :ok
  end

  def subscribe(repo, model, subscription_data, actions \\ []) do
    repo.insert(%Ecto.Subscribe.Schema.SystemTable{model: (model |> Atom.to_string),
                                                   subscription_info: subscription_data,
                                                   subscription_actions: actions_to_string(get_actions(actions))})
    :ok
  end

  def call_adapter(kw, changeset, action) do
    case List.keyfind(kw, :adapter, 0) do
      nil ->
        {:error, :wrong_adapter}
      {:adapter, adapter} ->
        (adapter).send(changeset, action)
    end
  end

  @doc """
  """
  defmacro subscribe(kw) do
    quote do
      use Ecto.Model.Callbacks
      
      after_insert :subscribe_after_insert, [__MODULE__, unquote(kw)]
      after_delete :subscribe_after_delete, [__MODULE__, unquote(kw)]
      after_update :subscribe_after_update, [__MODULE__, unquote(kw)]

      def subscribe_after_insert(changeset, model, kw) do
        execute(kw, changeset, model, :create)
        changeset
      end
      
      def subscribe_after_delete(changeset, model, kw) do
        execute(kw, changeset, model, :delete)
        changeset
      end
      
      def subscribe_after_update(changeset, model, kw) do
        execute(kw, changeset, model, :update)
        changeset
      end
    end
  end

  def execute(kw, changeset, model, action) do
    {_, repo} = List.keyfind(kw, :repo, 0)
    query_result = query_model_from_system_tbl(repo, model)
    case find_subscription(query_result, changeset, model, action) do
      :false ->
        :pass
      :true ->
        call_adapter(kw, changeset, action)
    end
  end

  def query_model_from_system_tbl(repo, model) do
    model = model |> Atom.to_string
    repo.all(from q in Ecto.Subscribe.Schema.SystemTable, where: q.model == ^model)
  end

  def get_actions([]) do
    [:create, :update, :deelte]
  end
  def get_actions(actions) do
    actions
  end

  def find_subscription([], _, _, _) do
    :false
  end

  def find_subscription([subscription_row_in_db | subscription_in_db], changeset, model, action) do
    find_subscription(subscription_row_in_db, subscription_in_db, changeset, model, action)
  end

  def find_subscription(subscription_row_in_db, subscription_in_db, changeset, model, action) do
    find_subscription_helper(subscription_row_in_db, subscription_in_db, changeset, model, action)
  end
  
  def find_subscription_helper(subscription_row_in_db, subscription_in_db, changeset, model, action) do
    actions = string_to_actions(subscription_row_in_db.subscription_actions)
    case Enum.member?(actions, action) do
      true ->
        {field_name, operator, val} = db_row_to_map(subscription_row_in_db.subscription_info, model)
				validate_change(changeset.changes, field_name, operator, val)
      false ->
        is_subscription_for_all(actions, subscription_in_db, changeset, model, action)
    end
  end

	def validate_change(changes, field_name, operator, val) do
		case Map.get(changes, field_name, 0) do
			nil ->
				:false
			updated_val ->
				case operator do
					"==" ->
						val == updated_val
					">" ->
						updated_val > val 
					"<" ->
						updated_val > val
					_ ->
						:false
				end
		end
	end

  def is_subscription_for_all([:all], _, _, _, _) do
    :true
  end

  def is_subscription_for_all(_, subscription_in_db, changeset, model, action) do
    find_subscription(subscription_in_db, changeset, model, action)
  end

  def db_row_to_map(str, model) do
    [name, operator, val] = String.split(str, " ")
    type = model.__schema__(:field, name |> String.to_atom)
    {String.to_atom(name), operator, get_val_with_correct_type_from_string(type, val)}
  end

  def actions_to_string(actions) do
    Enum.reduce(actions, "", fn(act, acc) -> acc <> (act |> Atom.to_string) <> "," end) |> String.strip ?,
  end

  def string_to_actions(str) do
    splitten_string = String.split(str, ",")
    for s <- splitten_string do
      s |> String.to_atom
    end
  end

  # TODO think about more flexible way how to convert to correct types
  def get_val_with_correct_type_from_string(type, val) do
    case type do
      :integer -> String.to_integer val
      :float   -> String.to_float val
      :boolean -> String.to_atom val
      _ -> val
    end
  end

end
