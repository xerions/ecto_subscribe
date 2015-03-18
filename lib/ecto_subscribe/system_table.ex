defmodule Ecto.Subscribe.Schema.SystemTable do
  use Ecto.Model
  @primary_key {:model, :string, []}
  schema "ecto_subscribe" do
    field :subscription_info, :string
    field :subscription_actions, :string
  end
end
