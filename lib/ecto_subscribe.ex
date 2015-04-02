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
    Ecto.Migration.Auto.migrate(repo, Ecto.Subscribe.Schema.SystemTable.Key)
    Ecto.Migration.Auto.migrate(repo, Ecto.Subscribe.Schema.SystemTable)
  end
end
