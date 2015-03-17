defmodule Ecto.Subscribe do
	use Application
	
	def start(_type, _args) do


		Application.put_env(:ecto_subscribe,
												Ecto.Subscribe.Repo,
												adapter: Ecto.Adapters.Postgres,
												url: "ecto://postgres:postgres@localhost/exd_test",
												size: 1,
												max_overflow: 0)

		import Supervisor.Spec
		tree = [worker(Ecto.Subscribe.Repo, [])]
		opts = [name: Ecto.Subscribe.Sup, strategy: :one_for_one]
		Supervisor.start_link(tree, opts)
	end
end
