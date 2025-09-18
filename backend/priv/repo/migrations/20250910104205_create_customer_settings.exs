defmodule DualflowTreasury.Repo.Migrations.CreateCustomerSettings do
  use Ecto.Migration

  def change do
    create table(:customer_settings) do
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :target_balance, :decimal, precision: 12, scale: 2
      add :auto_transfer_enabled, :boolean, default: true

      timestamps()
    end

    create unique_index(:customer_settings, [:customer_id])
  end
end
