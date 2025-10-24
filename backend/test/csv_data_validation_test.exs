defmodule DualflowTreasury.CsvDataValidationTest do
  use DualflowTreasury.DataCase

  describe "CSV file verification" do
    test "CSV file exists and has correct structure" do
      csv_path = Path.join([__DIR__, "..", "priv", "repo", "seeds", "user_1_test_user.csv"])

      # Test file exists
      assert File.exists?(csv_path)

      # Read and parse the CSV content
      content = File.read!(csv_path)
      lines = String.split(content, "\n", trim: true)

      # Should have at least header + some data rows
      assert length(lines) >= 2

      # Check header format (trim any carriage returns)
      header = List.first(lines) |> String.trim()
      assert header == "date,amount,merchant_id,description,category,is_recurring"

      # Check first data row format
      first_data_row = Enum.at(lines, 1) |> String.trim()
      [date, amount, merchant_id, description, category, is_recurring] =
        String.split(first_data_row, ",", parts: 6)

      # Verify the first transaction data (updated for decimal format)
      assert date == "2025-06-01"
      assert amount == "-12500.00"  # <-- Updated to match Excel format
      assert merchant_id == "DOWNTOWN_OFFICE_RENT"
      assert String.contains?(description, "Office Rent")
      assert category == "rent"
      assert is_recurring == "TRUE"  # <-- Excel also changed this

      IO.puts("✅ CSV file verified with #{length(lines)} total lines")
      IO.puts("✅ Header: #{header}")
      IO.puts("✅ First transaction: #{first_data_row}")

      # Test that we can parse dates and decimals
      assert {:ok, _parsed_date} = Date.from_iso8601(date)
      assert %Decimal{} = Decimal.new(amount)
    end
  end
end
