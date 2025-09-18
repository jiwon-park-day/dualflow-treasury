defmodule DualflowTreasuryWeb.PageController do
  use DualflowTreasuryWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
