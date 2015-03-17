defmodule Ecto.Subscribe.Repo do
  use Ecto.Repo,
  otp_app: :ecto_subscribe,
  adapter: Ecto.Adapters.Postgres
end
