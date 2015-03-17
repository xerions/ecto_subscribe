import Ecto.Subscribe.Api
import Exd.Model.Api, only: :macros

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
  use Ecto.Model
  subscribe(adapter: :log)
  schema "test_table2" do
    field :f, :string
  end
end

defmodule Test.Repo do
  use Ecto.Repo,
  otp_app: :exd,
  # TODO remove it
  adapter: TestDbHelper.get_adapter
end

defmodule EctoSubscribeTest do
  use ExUnit.Case

  {adapter, url} = case Mix.env do
                     :pg ->
                       {Ecto.Adapters.Postgres, "ecto://postgres:postgres@localhost/exd_test"}
                     _ ->
                       {Ecto.Adapters.MySQL, "ecto://root@localhost/exd_test"}
                   end
  
  Application.put_env(:exd,
                      Test.Repo,
                      adapter: adapter,
                      url: url,
                      size: 1,
                      max_overflow: 0)

  gen_api Weather2, Test.Repo

  test "ecto_subscribe test" do
    Ecto.Subscribe.Test.DbHelper.drop_db    
    Ecto.Subscribe.Test.DbHelper.create_db

    Test.Repo.start_link()
    Ecto.Migration.Auto.migrate(Test.Repo, Weather2)
    Ecto.Subscribe.Api.subscribe(Weather2, %{f: "test"}, [:create])
    Test.Repo.insert(%Weather2{f: "test"})

    Ecto.Subscribe.Test.DbHelper.drop_db
  end
  
end
