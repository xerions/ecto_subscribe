defmodule Ecto.Subscribe.Schema.SystemTable do
  use Ecto.Model
  schema "ecto_subscribe" do
    field :model, :string
    field :subscription_info, :string
    field :subscription_actions, :string
    field :adapter, :string
    field :receiver, :string
    field :callback, :string
  end
end

defmodule Ecto.Subscribe.Schema.SystemTable.Key do
  use Ecto.Model
  schema "ecto_subscribe_key" do
    field :model, :string
    field :key, :string
    field :subscription_info, :string
    field :subscription_actions, :string
    field :adapter, :string
    field :receiver, :string
    field :callback, :string
  end
end
