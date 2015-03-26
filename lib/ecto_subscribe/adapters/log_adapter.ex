defmodule Ecto.Subscribe.Adapter.Log do
  @behaviour Ecto.Subscribe.Adapter

  require Logger

  # TODO think about output format, now it is only for testing
  def send(opts, changeset, action) do
    Logger.info fn ->
      ["New event: ", action |> Atom.to_string, ". Changeset: ", changeset.changes |> inspect]
    end
    :ok
  end
end
