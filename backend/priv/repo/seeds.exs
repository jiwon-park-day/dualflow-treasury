# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DualflowTreasury.Repo.insert!(%DualflowTreasury.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DualflowTreasury.{Customers, Accounts, Treasury, Billing, CreditCards}
alias DualflowTreasury.Repo


# Clear existing data

IO.puts("Clearing existing data...")
Repo.delete_all(DualflowTreasury.Treasury.TransferDecision)
Repo.delete_all(DualflowTreasury.Treasury.Transaction)
Repo.delete_all(DualflowTreasury.Billing.RecurringBillHistory)
Repo.delete_all(DualflowTreasury.Billing.RecurringBill)
Repo.delete_all(DualflowTreasury.CreditCards.CreditCardTransaction)
Repo.delete_all(DualflowTreasury.CreditCards.CreditCard)
Repo.delete_all(DualflowTreasury.Accounts.InterestPayment)
Repo.delete_all(DualflowTreasury.Accounts.AccountDailySnapshot)
Repo.delete_all(DualflowTreasury.Accounts.Account)
Repo.delete_all(DualflowTreasury.Customers.CustomerSettings)
Repo.delete_all(DualflowTreasury.Customers.Customer)

IO.puts("\n")
IO.puts("✅ Database cleared")

IO.puts("\n")
IO.puts("➡️ DB seeding starting!")

# Create customer

IO.puts("\n")
IO.puts("Creating customer...")

{:ok, customer} = Customers.create_customer(%{
  company_name: "Test Corp",
  user_name: "test_corp",
  password: "password123"
})

IO.puts("\n")
IO.puts("   Customer ID: #{customer.id}")
IO.puts("   Company: #{customer.company_name}")
IO.puts("   Username: #{customer.user_name}")

IO.puts("\n")
IO.puts("Getting customer settings...")

{:ok, settings} = Customers.get_customer_settings(customer.id)

IO.puts("\n")
IO.puts("   Target Balance: #{settings.target_balance}")
IO.puts("   Auto-transfer: #{settings.auto_transfer_enabled}")

# Create accounts

IO.puts("\n")
IO.puts("Creating accounts...")

{:ok, accounts} = Accounts.create_customer_accounts(customer.id)

inv_pecentage = Decimal.mult(accounts.investment.interest_rate, Decimal.new("100"))
chk_pecentage = Decimal.mult(accounts.checking.interest_rate, Decimal.new("100"))


IO.puts("\n")
IO.puts("   Investment: ")
IO.puts("     Account ID: #{accounts.investment.id}")
IO.puts("     Current Balance: $#{accounts.investment.current_balance}")
IO.puts("     Interest Rate: #{inv_pecentage}%")

IO.puts("\n")
IO.puts("   Checking: ")
IO.puts("     Account ID: #{accounts.checking.id}")
IO.puts("     Current Balance: $#{accounts.checking.current_balance}")
IO.puts("     Interest Rate: #{chk_pecentage}%")

IO.puts("\n")
IO.puts("Adding starting balance...")

case Accounts.update_account_balance(accounts.checking.id, Decimal.new("1500000")) do
  {:ok, account} ->
    IO.puts("\n")
    IO.puts("   Updated Checking Balance: $#{account.current_balance}")

  {:error, reason} ->
    IO.puts("\n")
    IO.puts("   Failed to update account balance: #{inspect(reason)}")
    raise "Account update failed"
end


# Create credit card

IO.puts("\n")
IO.puts("Creating credit card...")

{:ok, card} = CreditCards.create_customer_credit_card(customer.id, Decimal.new("1000000"))

IO.puts("\n")
IO.puts("   Credit Card ID: #{card.id}")
IO.puts("   Current Balance: $#{card.current_balance}")
IO.puts("   Statement Balance: $#{card.statement_balance}")
IO.puts("   Credit Limit: $#{card.credit_limit}")
IO.puts("   Statement Closing Day: #{card.statement_closing_day}")
IO.puts("   Payment Due Day: #{card.payment_due_day}")

# Import historical data

IO.puts("\n")
IO.puts("Importing historical transactions...")

csv_path = Path.join([__DIR__, "seeds", "user_1_test_user.csv"])

case Treasury.import_historical_transactions(customer.id, csv_path) do
  {:ok, transactions} ->
    IO.puts("\n")
    IO.puts("   Imported #{length(transactions)} transactions")

  {:error, reason} ->
    IO.puts("\n")
    IO.puts("   Failed to import transactions: #{inspect(reason)}")
    raise "Transaction import failed"
end

# Final account balances

IO.puts("\n")
IO.puts("Getting final balances...")

{:ok, inv_bal} = Accounts.get_account_balance(accounts.investment.id)
{:ok, chk_bal} = Accounts.get_account_balance(accounts.checking.id)

IO.puts("\n")
IO.puts("   Investment: $#{inv_bal}")
IO.puts("   Checking: $#{chk_bal}")

# Recurring bills

IO.puts("\n")
IO.puts("Getting recurring bills...")

{:ok, bills} = Billing.get_account_recurring_bills(accounts.checking.id)

IO.puts("\n")
IO.puts("   Total bills: #{length(bills)}")

bills
|> Enum.sort_by(& &1.monthly_due_day)
|> Enum.each(fn bill ->
  IO.puts("     #{bill.description} (Day #{bill.monthly_due_day}: $#{bill.predicted_amount})")
end)


IO.puts("\n")
IO.puts("✨ DB seeding completed!")

IO.puts("\n")
IO.puts("Login credentials:")
IO.puts("   Username: test_corp")
IO.puts("   Password: password123")
