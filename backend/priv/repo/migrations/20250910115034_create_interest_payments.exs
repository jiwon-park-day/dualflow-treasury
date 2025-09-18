defmodule DualflowTreasury.Repo.Migrations.CreateInterestPayments do
  use Ecto.Migration

  def change do
    create table(:interest_payments) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :payment_date, :date, null: false
      add :period_end_date, :date, null: false
      add :amount, :decimal, precision: 12, scale: 2
    end

    create index(:interest_payments, [:account_id])
    create index(:interest_payments, [:account_id, :period_end_date])

  end
end
