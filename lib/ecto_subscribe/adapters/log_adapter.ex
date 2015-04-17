defmodule Ecto.Subscribe.Adapter.Log do
  @behaviour Ecto.Subscribe.Adapter

  require Logger

  def send(opts, changeset, action) do
    Logger.info fn ->
      ["New event: ", action |> Atom.to_string, ". Changeset: ", changeset |> inspect]
    end
    :ok
  end
end
