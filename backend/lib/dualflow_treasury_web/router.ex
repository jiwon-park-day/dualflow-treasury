defmodule DualflowTreasuryWeb.Router do
  use DualflowTreasuryWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DualflowTreasuryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Browser
  scope "/", DualflowTreasuryWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # API
  scope "/api", DualflowTreasuryWeb.API do
    pipe_through :api

    get "/dashboard", DashboardController, :show
    get "/credit-card", CreditCardController, :show
    get "/banking", BankingController, :show
    get "/accounts/investment", AccountController, :show_investment
    get "/accounts/checking", AccountController, :show_checking
    patch "/accounts/checking/target-balance", AccountController, :update_target_balance
    get "/settings", SettingsController, :show
    patch "/settings/profile", SettingsController, :update_profile
    put "/settings/password", SettingsController, :update_password
    patch "/settings/auto-transfer", SettingsController, :toggle_auto_transfer
    patch "/settings/target-balance", SettingsController, :update_target_balance
    patch "/settings/credit-card", SettingsController, :update_credit_card
  end

  # Simulator (Admin-only)
  scope "/api/admin/simulator", DualflowTreasuryWeb do
    pipe_through :api
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:dualflow_treasury, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DualflowTreasuryWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
