defmodule DualflowTreasury.Repo.Migrations.FixNullableConstraints do
  use Ecto.Migration

  def change do
    # Add NOT NULL constraints to required fields
    alter table(:customers) do
      modify :company_name, :string, null: false
      modify :user_name, :string, null: false
      modify :password_hash, :string, null: false
    end

    alter table(:account_daily_snapshots) do
      modify :ending_balance, :decimal, precision: 12, scale: 2, null: false
      modify :interest_earned, :decimal, precision: 12, scale: 2, null: false
      modify :cumulative_interest, :decimal, precision: 12, scale: 2, null: false
    end

    alter table(:interest_payments) do
      modify :amount, :decimal, precision: 12, scale: 2, null: false
    end

    alter table(:transactions) do
      modify :amount, :decimal, precision: 12, scale: 2, null: false
    end

    alter table(:transfer_decisions) do
      modify :amount, :decimal, precision: 12, scale: 2, null: false
      modify :predicted_bills_amount, :decimal, precision: 12, scale: 2, null: false
      modify :target_balance, :decimal, precision: 12, scale: 2, null: false
    end

    alter table(:credit_cards) do
      modify :credit_limit, :decimal, precision: 12, scale: 2, null: false
    end

    alter table(:credit_card_transactions) do
      modify :amount, :decimal, precision: 12, scale: 2, null: false
    end


    # Change foreign key constraints: nilify_all -> delete_all
    drop constraint(:recurring_bill_history,  "recurring_bill_history_transaction_id_fkey")
    drop constraint(:transfer_decisions, "transfer_decisions_dest_transaction_id_fkey")

    alter table(:recurring_bill_history) do
      modify :transaction_id, references(:transactions, on_delete: :delete_all), null: false
    end

    alter table(:transfer_decisions) do
      modify :dest_transaction_id, references(:transactions, on_delete: :delete_all), null: false
    end

  end
end
