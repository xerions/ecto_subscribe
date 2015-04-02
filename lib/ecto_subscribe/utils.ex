defmodule Ecto.Subscribe.Utils do
  @doc """
  Converts list of the atoms to the separated by commas string.
  """  
  def actions_to_string(actions) do
    Enum.reduce(actions, "", fn(act, acc) -> acc <> (act |> Atom.to_string) <> "," end) |> String.strip ?,
  end
  
  @doc """
  actions_to_string inverse function. Takes string with actions
  separated by commas and return list of atoms.
  """
  def string_to_actions(str) do
    splitten_string = String.split(str, ",")
    for s <- splitten_string do
      s |> String.to_atom
    end
  end

  @doc """
  Returns primary key from a model converted to string.
  """
  def get_primary_key_str(model) do
    [key] = model.__schema__(:primary_key)
    key |> Atom.to_string
  end

  @doc """
  This function is used by the Ecto.Subscribe.Api.subscribe/4 to get list of 
  actions. If empty string passed, all possible actions will be returned.
  """
  def get_actions("") do
    [:create, :update, :delete]
  end

  def get_actions(actions) do
    actions
  end  
end
