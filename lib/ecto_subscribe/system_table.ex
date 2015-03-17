defmodule Ecto.Subscribe.Schema.SystemTable do
  use Ecto.Model
  @primary_key {:model, :string, []}
  schema "ecto_subscribe" do
      field :subscription_info, :string
      field :subscription_actions, :string
  end
end

defmodule Ecto.Subscribe.Migration.SystemTable do
  use Ecto.Migration
  def up do
    create table(:ecto_subscribe) do
      add :model, :string
      add :subscription_info, :string
      add :subscription_actions, :string
    end
  end
end
