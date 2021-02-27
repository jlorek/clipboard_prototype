# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :clipboard,
  ecto_repos: [Clipboard.Repo]

# Configures the endpoint
config :clipboard, ClipboardWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xGVWE4ilTu9L1ClaTG+Wj+rT5Q5f+mv6PK4nIUPhTOm5BfcJzlBQf6iew1h5lMss",
  render_errors: [view: ClipboardWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Clipboard.PubSub,
  live_view: [signing_salt: "/aBw0FMp"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
