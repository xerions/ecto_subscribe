import Ecto.Subscribe.Api

import Ecto.Query

defmodule TestModel do
  use Ecto.Schema
  subscribe(repo: EctoIt.Repo)
  schema "ecto_subscribe_test_table" do
    field :f, :string
    field :i, :integer
  end
end

defmodule EctoSubscribeTest do
  use ExUnit.Case, async: false
  test "ecto_subscribe test, you can see two log output" do
    :ok = :application.start(:ecto_it)
    Ecto.Migration.Auto.migrate(EctoIt.Repo, TestModel)
    Ecto.Subscribe.init(EctoIt.Repo)

    Ecto.Subscribe.Api.subscribe(EctoIt.Repo, TestModel, "id > 0", [adapter: Ecto.Subscribe.Adapter.Log])
    Ecto.Subscribe.Api.subscribe(EctoIt.Repo, TestModel, "i > 10", [adapter: Ecto.Subscribe.Adapter.Log])
    EctoIt.Repo.insert(%TestModel{f: "test",  i: 100})
    EctoIt.Repo.insert(%TestModel{f: "test2", i: 100})

    query = from s in Ecto.Subscribe.Schema.SystemTable, select: s
    [result] = EctoIt.Repo.all(query)
    assert result.adapter == "Elixir.Ecto.Subscribe.Adapter.Log"
    assert result.model == "TestModel"
    assert result.subscription_actions == "create,update,delete"
    assert result.subscription_info == "i > 10"

    query = from s in Ecto.Subscribe.Schema.SystemTable.Key, select: s
    [result] = EctoIt.Repo.all(query)
    assert result.adapter == "Elixir.Ecto.Subscribe.Adapter.Log"
    assert result.model == "TestModel"
    assert result.subscription_actions == "create,update,delete"
    assert result.subscription_info == "id > 0"

    :ok = :application.stop(:ecto_it)
  end
end
