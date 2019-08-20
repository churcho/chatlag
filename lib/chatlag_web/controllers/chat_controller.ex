defmodule ChatlagWeb.ChatController do
  use ChatlagWeb, :controller
  # alias Chatlag.Chat

  plug :put_layout, "chat.html" when action in [:chat]
  plug :put_layout, "front.html" when action in [:index]

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Lobby,
      session: %{user_id: user_id}
    )
  end

  def chat(conn, %{"id" => room_id}) do
    user_id = get_session(conn, :user_id)

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Chat,
      session: %{room_id: room_id, user_id: user_id}
    )
  end

  def create_room(conn, %{"id1" => id1, "id2" => id2}) do
    # user_id = String.to_integer(get_session(conn, :id1))

    IO.inspect("Chat #{id1} - #{id2}")
    user_id = get_session(conn, :user_id)

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Chat,
      session: %{room_id: 46, user_id: user_id}
    )
  end
end
