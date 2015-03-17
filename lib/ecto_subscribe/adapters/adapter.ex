defmodule Ecto.Subscribe.Adapter do
  use Behaviour

  defcallback send(Ecto.Changeset.t, atom) :: atom
end
