defmodule Chatlag.Auth do
  use ChatlagWeb, :controller
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = user_id && Chatlag.Accounts.get_user!(user_id)
      assign(conn, :current_user, user)
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Routes.auth_path(conn, :login))
      |> halt()
    end
  end

  def login(conn, user) do
    # to_string(:inet_parse.ntoa(conn.remote_ip))
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end
end
