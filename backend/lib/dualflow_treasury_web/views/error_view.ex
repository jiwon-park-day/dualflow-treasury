defmodule DualflowTreasuryWeb.ErrorView do
  @moduledoc """
  Renders error responses as JSON.

  Handles HTTP error status codes and formats them into consistent JSON responses.
  Used by FallbackController to render error tuples from context functions.
  """

  def render("404.json", %{error: error}) do
    %{error: "Not found", detail: error}
  end

  def render("422.json", %{error: error}) do
    %{error: "Unprocessable entity", detail: error}
  end

  def render("422.json", %{changeset: changeset}) do
    %{error: "Validation failed", details: translate_errors(changeset)}
  end

  def render("500.json", %{error: error}) do
    %{error: "Internal server error", detail: error}
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
