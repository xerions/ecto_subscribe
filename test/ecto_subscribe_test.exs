import Ecto.Subscribe.Api

Code.require_file "test/db/dbhelper.ex"

defmodule TestDbHelper do
  def get_adapter do
    case Mix.env do
      :pg ->
        Ecto.Adapters.Postgres
      _ ->
        Ecto.Adapters.MySQL
    end
  end
end

defmodule Weather2 do
  use Ecto.Schema
  subscribe(adapter: Ecto.Subscribe.Adapter.Log, repo: Test.Repo)
  schema "test_table2" do
    field :f, :string
    field :i, :integer
  end
end

defmodule Test.Repo do
  use Ecto.Repo,
  otp_app: :ecto_subscribe,
  # TODO remove it
  adapter: TestDbHelper.get_adapter
end

defmodule EctoSubscribeTest do
  use ExUnit.Case

  {adapter, url} = case Mix.env do
                     :pg ->
                       {Ecto.Adapters.Postgres, "ecto://postgres:postgres@localhost/ecto_subscribe_test"}
                     _ ->
                       {Ecto.Adapters.MySQL, "ecto://root@localhost/ecto_subscribe_test"}
                   end
  
  Application.put_env(:ecto_subscribe,
                      Test.Repo,
                      adapter: adapter,
                      url: url,
                      size: 1,
                      max_overflow: 0)

  test "ecto_subscribe test" do
    Ecto.Subscribe.Test.DbHelper.drop_db    
    Ecto.Subscribe.Test.DbHelper.create_db

    Test.Repo.start_link()
    Ecto.Migration.Auto.migrate(Test.Repo, Weather2)

    Ecto.Subscribe.init(Test.Repo)
    Ecto.Subscribe.Api.subscribe(Test.Repo, Weather2, "i > 0", [:create])

    Test.Repo.insert(%Weather2{f: "test", i: 100})
    Test.Repo.delete(%Weather2{id: 1})

    Ecto.Subscribe.Test.DbHelper.drop_db
  end
end
