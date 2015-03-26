defmodule Ecto.Subscribe.Adapter.Remote do
  @behaviour Ecto.Subscribe.Adapter

  # TODO
  #  Now it is hardcoded Elixir.Exd.Script.Subscription.Handler module
  #  if can leave it as is if we will use this adapter only from script
  #  and need update it and pass callback module if this adapter will
  #  be used not only from exd script
  def send(opts, changeset, action) do
    :rpc.call(opts.receiver |> String.to_atom, :'Elixir.Exd.Script.Subscription.Handler', :subscription_event, [changeset, action])
  end
end
