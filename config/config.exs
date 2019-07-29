# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :chatlag,
  ecto_repos: [Chatlag.Repo]

# Configures the endpoint
config :chatlag, ChatlagWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SQwMkSIXsaG5JmPNfz3+ZgfyxZE4p/Y47cj/w8FDUg13C4l4gQAmXinYit8XH/6w",
  render_errors: [view: ChatlagWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Chatlag.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

#live view
config :chatlag, ChatlagWeb.Endpoint,
  live_view: [
    signing_salt: "gPHQm6yxSF6JzQHAMS0Y1QRsIsJ19rzI"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
