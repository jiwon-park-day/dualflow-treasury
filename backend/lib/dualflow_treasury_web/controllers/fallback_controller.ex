defmodule DualflowTreasuryWeb.FallbackController do
  @moduledoc """
  Handles error tuples from context functions and converts them to appropriate HTTP responses.

  Returns 404 for not found errors, 422 for business logic and validation errors, and 500 for unexpected errors.
  """
  use DualflowTreasuryWeb, :controller

  alias DualflowTreasuryWeb.ErrorView

  # Not Found errors
  def call(conn, {:error, error})
      when error in [
             :customer_not_found,
             :settings_not_found,
             :account_not_found,
             :investment_account_not_found,
             :checking_account_not_found,
             :snapshot_not_found,
             :payment_not_found,
             :transaction_not_found,
             :decision_not_found,
             :bill_not_found,
             :card_not_found
           ] do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render("404.json", error: error)
  end

  # Business logic errors
  def call(conn, {:error, error})
      when error in [
             :invalid_credentials,
             :not_first_day_of_month,
             :insufficient_history,
             :invalid_payment_amount
           ] do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ErrorView)
    |> render("422.json", error: error)
  end

  # Changeset validation error
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ErrorView)
    |> render("422.json", changeset: changeset)
  end

  # Catch-all
  def call(conn, {:error, reason}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(ErrorView)
    |> render("500.json", error: reason)
  end
end
