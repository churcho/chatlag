defmodule Chatlag.Repo do
  use Ecto.Repo,
    otp_app: :chatlag,
    adapter: Ecto.Adapters.Postgres
end
