# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :elixir_demo,
  ecto_repos: [ElixirDemo.Repo]

# Configures the endpoint
config :elixir_demo, ElixirDemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/tS7G0Ff4AV911OKTe5ESsA2tbZG5YZnPNlcyzBhb0RyiPpDIDnfVZJWCJueEfEW",
  render_errors: [view: ElixirDemoWeb.ErrorView, accepts: ~w(html json)],
  live_view: [
    signing_salt: "bNOeToVq3Xls/4glUUTmaBo6uaCYbOdK"
  ],
  pubsub: [name: ElixirDemo.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
