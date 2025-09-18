defmodule DualflowTreasury.Billing.RecurringBillHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recurring_bill_history" do
    field(:actual_amount, :decimal)
    field(:predicted_amount, :decimal)
    field(:prediction_error, :decimal)

    belongs_to :bill, DualflowTreasury.Billing.RecurringBill
    belongs_to :transaction, DualflowTreasury.Treasury.Transaction

    timestamps(updated_at: false)
  end

  def changeset(history, attrs) do
    history
    |> cast(attrs, [:actual_amount, :predicted_amount, :bill_id, :transaction_id])    # Prediction error internally calculated
    |> validate_required([:actual_amount, :bill_id, :transaction_id])     # New bills don't have prediction data
    |> validate_number(:actual_amount, greater_than: 0)
    |> validate_predicted_amount()
    |> calculate_prediction_error()
    |> unique_constraint(:transaction_id)
    |> foreign_key_constraint(:bill_id)
    |> foreign_key_constraint(:transaction_id)
  end

  defp validate_predicted_amount(changeset) do
    case get_field(changeset, :predicted_amount) do
      nil -> changeset
      amount -> validate_number(changeset, :predicted_amount, greater_than: 0)
    end
  end

  defp calculate_prediction_error(changeset) do
    actual = get_field(changeset, :actual_amount)
    predicted = get_field(changeset, :predicted_amount)

    if actual && predicted do
      error = Decimal.sub(actual, predicted)
      put_change(changeset, :prediction_error, error)
    else
      changeset
    end
  end
end
