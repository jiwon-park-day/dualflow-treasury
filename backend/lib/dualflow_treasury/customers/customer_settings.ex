defmodule DualflowTreasury.Customers.CustomerSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customer_settings" do
    field :target_balance, :decimal
    field :auto_transfer_enabled, :boolean, default: true

    belongs_to :customer, DualflowTreasury.Customers.Customer

    timestamps()
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:target_balance, :auto_transfer_enabled, :customer_id])
    |> validate_required([:customer_id])
    |> validate_number(:target_balance, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:customer_id)
    |> unique_constraint(:customer_id)
  end

end
