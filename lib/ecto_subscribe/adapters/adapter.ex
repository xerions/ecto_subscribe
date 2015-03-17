defmodule Ecto.Subscribe.Adapter do
  use Behaviour

  def available_adapters do
    [:log]
  end
  
  defcallback send(Ecto.Changeset.t, atom) :: atom
end
