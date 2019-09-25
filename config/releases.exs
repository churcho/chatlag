# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

IO.puts("start...")

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :chatlag, Chatlag.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :chatlag, Chatlag.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN"),
  hackney: [
    recv_timeout: 5 * 60 * 1000
  ]

config :chatlag, ChatlagWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "9040")],
  https: [
    :inet6,
    port: 443,
    cipher_suite: :strong,
    keyfile: System.get_env("APP_SSL_KEY_PATH"),
    certfile: System.get_env("APP_SSL_CERT_PATH")
  ],

  # https: [
  #   port: 9041,
  #   cipher_suite: :strong,
  #   certfile: "priv/cert/selfsigned.pem",
  #   keyfile: "priv/cert/selfsigned_key.pem"
  # ],
  secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :chatlag, ChatlagWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
