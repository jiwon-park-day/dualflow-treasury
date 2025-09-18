defmodule DualflowTreasury.Repo.Migrations.CreateRecurringBills do
  use Ecto.Migration

  def change do
    create table(:recurring_bills) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :merchant_id, :string, null: false
      add :description, :string
      add :predicted_amount, :decimal, precision: 12, scale: 2, null: false   # 'predicted_amount = actual_amount' for new bills
      add :monthly_due_day, :integer, null: false
      add :is_active, :boolean, default: true

      timestamps()

    end

    create index(:recurring_bills, [:account_id])
    create index(:recurring_bills, [:account_id, :merchant_id])
    create index(:recurring_bills, [:account_id, :monthly_due_day])
    create index(:recurring_bills, [:account_id, :is_active])
  end
end
