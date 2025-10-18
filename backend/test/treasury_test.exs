defmodule DualflowTreasury.TreasuryTest do
  use DualflowTreasury.DataCase
  alias DualflowTreasury.Treasury

  test "parse_transaction_csv/1 parses CSV correctly" do
    csv_path = Path.join([__DIR__, "..", "priv", "repo", "seeds", "user_1_test_user.csv"])
    
    assert {:ok, transactions} = Treasury.parse_transaction_csv(csv_path)
    
    assert length(transactions) == 84
    
    first_txn = List.first(transactions)
    assert first_txn.date == ~D[2025-06-01]
    assert first_txn.amount == Decimal.new("-12500.00")
    assert first_txn.merchant_id == "DOWNTOWN_OFFICE_RENT"
    assert first_txn.is_recurring == true
    
    IO.puts("✅ Parsed #{length(transactions)} transactions successfully")
  end
end