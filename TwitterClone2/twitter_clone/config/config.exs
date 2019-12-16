# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :twitter_clone,
  ecto_repos: [TwitterClone.Repo]

# Configures the endpoint
config :twitter_clone, TwitterCloneWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zytOOJ8s7I9pHOSuTSYBWKTC0x8nnmbp3WZLLN6XXmmclZ9Jc4DJ/LZA1MlL8yk/",
  render_errors: [view: TwitterCloneWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterClone.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
