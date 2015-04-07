defmodule Ecto.Subscribe.Api do
  import Ecto.Model.Callbacks
  import Ecto.Subscribe.Utils
  import Ecto.Subscribe.Executor

  @moduledoc """
  ecto_subscribe - is a ecto-based library. It provides ability to subscribe on
  changing data in the database.

  ## ecto_subscribe API

  First of all ecto_subscribe provides Ecto.Subscribe.Api.subscribe/1 macro
  for adding it into schema definition.

  For example:

      import Ecto.Subscribe.Api

      defmodule TestModel do
        use Ecto.Schema
        subscribe(repo: EctoIt.Repo)
        schema "table_name" do
          field :f, :string
          field :i, :integer
        end
      end

  Ecto.Subscribe.Api.subscribe/1 macro generates callback functions for the
  given schema which will react on any data changes as update, create or
  delete.

  ## Subscription

  There are two functions for subscription on data changes:

  Ecto.Subscribe.Api/4 is for subscription on all data changes in the model.
  It takes three arguments:

    * `repo` - Ecto.Repo;
    * `model` - Ecto.Model;
    * `opts` - read bellow about options.

  Second function is Ecto.Subscribe.Api.subscribe/4. It takes the same set
  of parameters, but the third paramter is string which represents subscription
  condition and options is fourth paramter.

  ## Example

      Ecto.Subscribe.Api.subscribe(EctoIt.Repo, TestModel, "id > 0", [adapter: Ecto.Subscribe.Adapter.Log])

  This call will execute subscription on the `TestModel`. All events (update/create/delete)
  which are will occur with the `TestModel` where `id > 0` will be written to the log.

  ## Subscription options

  All Ecto.Subscribe.Api.subscribe functions take `opts` as the last paramter.
  `ecto_subscribe` supports following options:

    * `adapter` - can be `Ecto.Subscribe.Adapter.Log` or `Ecto.Subscribe.Adapter.Remote`.
All events will be written to the log in the first case and sent over erlang RPC in the second;
    * `receiver` - must be erlang `node` where to send RPC request. Used only by `Ecto.Subscribe.Adapter.Remote`;
    * `callback` - must be function name which will be called via RPC. Used only by `Ecto.Subscribe.Adapter.Remote`;
  """

  def subscribe(repo, model, opts) do
    repo.insert(%Ecto.Subscribe.Schema.SystemTable{model: (model |> Macro.to_string),
                                                   subscription_info: "all",
                                                   subscription_actions: "all",
                                                   adapter: get_opts_field(opts, :adapter),
                                                   receiver: get_opts_field(opts, :receiver),
                                                   callback: get_opts_field(opts, :callback)})
    :ok
  end

  def subscribe(repo, model, subscription_data, opts) do
    [field_name, _, _] = String.split(subscription_data, " ")
    table_content = %{model: (model |> Macro.to_string),
                      subscription_info: subscription_data,
                      subscription_actions: actions_to_string(get_actions(get_opts_field(opts, :actions))),
                      adapter: get_opts_field(opts, :adapter),
                      receiver: get_opts_field(opts, :receiver),
                      callback: get_opts_field(opts, :callback)}

    case model.__schema__(:primary_key) == [field_name |> String.to_atom] do
      true ->
        table_content = Map.put_new(table_content, :key, field_name)
        new_system_table_entry = %Ecto.Subscribe.Schema.SystemTable.Key{}
        repo.insert(Map.merge(new_system_table_entry, table_content))
      false ->
        new_system_table_entry = %Ecto.Subscribe.Schema.SystemTable{}
        repo.insert(Map.merge(new_system_table_entry, table_content))
    end
    :ok
  end

  defmacro subscribe(kw) do
    quote do
      use Ecto.Model.Callbacks
      after_insert :subscribe_after_insert, [__MODULE__, unquote(kw)]
      after_delete :subscribe_after_delete, [__MODULE__, unquote(kw)]
      after_update :subscribe_after_update, [__MODULE__, unquote(kw)]

      def subscribe_after_insert(changeset, model, kw) do
        {_, repo} = List.keyfind(kw, :repo, 0)
        execute(repo, changeset, model, :create)
        changeset
      end
      
      def subscribe_after_delete(changeset, model, kw) do
        {_, repo} = List.keyfind(kw, :repo, 0)
        execute(repo, changeset, model, :delete)
        changeset
      end
      
      def subscribe_after_update(changeset, model, kw) do
        {_, repo} = List.keyfind(kw, :repo, 0)
        execute(repo, changeset, model, :update)
        changeset
      end
    end
  end

  defp get_opts_field(opts, field) do
    case List.keyfind(opts, field, 0) do
      nil ->
        ""
      {_, val} when is_list(val) ->
        val
      {_, val} ->
        val |> to_string
    end
  end
end
