defmodule Ecto.Subscribe.Adapter do
  use Behaviour

  @doc """
  """
  defcallback send(map, Ecto.Changeset.t, atom) :: atom
end
