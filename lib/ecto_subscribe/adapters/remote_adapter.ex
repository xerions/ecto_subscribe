defmodule Ecto.Subscribe.Adapter.Remote do
  @behaviour Ecto.Subscribe.Adapter

  def send(opts, changeset, action) do
    :rpc.call(opts.receiver |> String.to_atom, opts.callback |> String.to_atom, :subscription_event, [changeset, action])
  end
end
