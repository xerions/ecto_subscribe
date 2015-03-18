defmodule Ecto.Subscribe do
  use Application
  import Ecto.Query

  def start(_type, _args) do
    import Supervisor.Spec
    tree = []
    opts = [name: Ecto.Subscribe.Sup, strategy: :one_for_one]
    Supervisor.start_link(tree, opts)
  end

  def init(repo) do
    # we need to check existence of the ecto_subsribe table
    # in the database, and create it table if it does not
    # exists.
    try do
      repo.all(from table in Ecto.Subscribe.Schema.SystemTable, where: table.tablename == "ecto_subscribe", select: table, limit: 1)
    catch
      _, _ -> Ecto.Migration.Auto.migrate(repo, Ecto.Subscribe.Schema.SystemTable)
    end
  end
end
