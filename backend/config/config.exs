# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dualflow_treasury,
  ecto_repos: [DualflowTreasury.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :dualflow_treasury, DualflowTreasuryWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DualflowTreasuryWeb.ErrorHTML, json: DualflowTreasuryWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DualflowTreasury.PubSub,
  live_view: [signing_salt: "XFX+vgZO"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :dualflow_treasury, DualflowTreasury.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  dualflow_treasury: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  dualflow_treasury: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Oban
# Replaces basic Oban.Plugins.Cron in plugins list
config :dualflow_treasury, Oban,
  repo: DualflowTreasury.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    # {Oban.Plugins.Cron,
    #  timezone: "America/Denver",
    #  crontab: [
    #    # Daily Jobs

    #    # 12:00 AM - Calculate daily interest and create snapshots
    #    {"0 0 * * *", DualflowTreasury.Jobs.DailyInterestJob, queue: :daily_operations},

    #    # 7:00 AM - Settle next-day transfers (INV → CHK)
    #    {"0 7 * * *", DualflowTreasury.Jobs.DailyNextDaySettlementJob, queue: :daily_operations},

    #    # 7:00 PM - Make daily transfer decisions
    #    {"0 19 * * *", DualflowTreasury.Jobs.DailyTransferDecisionJob, queue: :daily_operations},

    #    # 10:00 PM - Settle same-day transfers (CHK → INV)
    #    {"0 22 * * *", DualflowTreasury.Jobs.DailySameDaySettlementJob, queue: :daily_operations},

    #    # Monthly Jobs

    #    # 1st of month, 1:00 AM - Process monthly interest payments
    #    {"0 1 1 * *", DualflowTreasury.Jobs.MonthlyInterestPaymentJob, queue: :monthly_operations},

    #    # 10th of month, 9:00 AM - Process automatic credit card payments
    #    {"0 9 10 * *", DualflowTreasury.Jobs.MonthlyCreditCardPaymentJob,
    #     queue: :monthly_operations},

    #    # 15th of month, 11:59 PM - Close credit card statements
    #    {"59 23 15 * *", DualflowTreasury.Jobs.MonthlyCreditCardStatementClosingJob,
    #     queue: :monthly_operations}
    #  ]}
  ],
  queues: [
    daily_operations: 10,
    monthly_operations: 5,
    simulation: 3
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
