defmodule Chatlag.Auth do
  use ChatlagWeb, :controller
  import Plug.Conn
  alias ChatlagWeb.Presence

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = user_id && Chatlag.Accounts.get_user!(user_id)

      Presence.track(
        self(),
        "chatlag",
        user.nickname,
        %{
          user_id: user_id,
          nickname: user.nickname
        }
      )

      assign(conn, :current_user, user)
    else
      conn = put_session(conn, :old_path, conn.request_path)

      conn
      |> redirect(to: Routes.auth_path(conn, :login))
      |> halt()
    end
  end

  # def login(conn, user) do
  #   # to_string(:inet_parse.ntoa(conn.remote_ip))
  #   conn
  #   |> assign(:current_user, user)
  #   |> put_session(:user_id, user.id)
  #   |> configure_session(renew: true)
  # end
end
