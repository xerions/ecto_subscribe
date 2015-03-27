import Ecto.Subscribe.Api

import Ecto.Query

defmodule TestModel do
  use Ecto.Schema
  @primary_key false
  subscribe(repo: EctoIt.get_repo())
  schema "test_table2" do
    field :f, :string, primary_key: true
    field :i, :integer
  end
end

defmodule EctoSubscribeTest do
  use ExUnit.Case
  test "ecto_subscribe test" do
    :ok = :application.start(:ecto_it)
    repo = EctoIt.get_repo()
    Ecto.Migration.Auto.migrate(repo, TestModel)
    Ecto.Subscribe.init(repo)
    Ecto.Subscribe.Api.subscribe(repo, TestModel, "i > 0", [adapter: Ecto.Subscribe.Adapter.Log])
    repo.insert(%TestModel{f: "test", i: 100})

    query = from s in Ecto.Subscribe.Schema.SystemTable, select: s
    [result] = repo.all(query)
    assert result.adapter == "Elixir.Ecto.Subscribe.Adapter.Log"
    assert result.model == "TestModel"
    assert result.subscription_actions == "create,update,delete"
    assert result.subscription_info == "i > 0"
    :ok = :application.stop(:ecto_it)
  end
end
