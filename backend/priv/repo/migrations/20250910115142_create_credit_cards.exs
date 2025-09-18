defmodule DualflowTreasury.Repo.Migrations.CreateCreditCards do
  use Ecto.Migration

  def change do
    create table(:credit_cards) do
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :card_name, :string
      add :current_balance, :decimal, precision: 12, scale: 2, default: 0.00
      add :statement_balance, :decimal, precision: 12, scale: 2, default: 0.00
      add :credit_limit, :decimal, precision: 12, scale: 2
      add :statement_closing_day, :integer, null: false
      add :payment_due_day, :integer, null: false
      add :min_payment, :decimal, precision: 12, scale: 2
      add :apr, :decimal, precision: 5, scale: 4
    end

    create index(:credit_cards, [:customer_id])

  end
end
