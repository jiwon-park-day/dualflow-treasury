defmodule DualflowTreasury.Repo.Migrations.AddMissingUniqueIndexes do
  use Ecto.Migration

  def change do
    # User names must be unique
    create unique_index(:customers, [:user_name])

    # Each account can only have one interest payment per period
    drop index(:interest_payments, [:account_id, :period_end_date])
    create unique_index(:interest_payments, [:account_id, :period_end_date])

    # Each transaction can only have one bill history associated
    drop index(:recurring_bill_history, [:transaction_id])
    create unique_index(:recurring_bill_history, [:transaction_id])

    # Each customer can only have one credit card
    drop index(:credit_cards, [:customer_id])
    create unique_index(:credit_cards, [:customer_id])

  end
end
