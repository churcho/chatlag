defmodule ChatlagWeb.LobbyController do
  use ChatlagWeb, :controller

  plug :put_layout, "empty.html" when action in [:index]
  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    current_user = Pow.Plug.current_user(conn)

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Frontpage,
      session: %{user_id: user_id, current_user: current_user}
    )
  end
end
