defmodule ChatlagWeb.ChatController do
  use ChatlagWeb, :controller
  alias Chatlag.Chat

  plug :put_layout, "chat.html" when action in [:chat]
  plug :put_layout, "front.html" when action in [:index]

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    current_user = Pow.Plug.current_user(conn)

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Lobby,
      session: %{user_id: user_id, current_user: current_user}
    )
  end

  def upload(conn, params) do
    IO.inspect(params, label: "Upload.....")

    conn
    |> send_resp(200, "")
  end

  def chat(conn, %{"id" => room_id}) do
    user_id = get_session(conn, :user_id)
    room = Chat.get_room!(room_id)

    if room.title =~ ~r/room_(\d+)_(\d+)/ do
      [[_, u1, u2]] = Regex.scan(~r/room_(\d+)_(\d+)/, room.title)

      u1 = String.to_integer(u1)
      u2 = String.to_integer(u2)

      valid = user_id == u1 or user_id == u2

      if !valid do
        conn
        |> redirect(to: "/")
        |> halt
      end
    end

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Chat,
      session: %{room_id: room_id, user_id: user_id, token: get_csrf_token()}
    )
  end

  def create_room(conn, %{"u1" => id1, "u2" => id2}) do
    user_id = get_session(conn, :user_id)

    valid = user_id == String.to_integer(id1) or user_id == String.to_integer(id2)

    case valid do
      true ->
        room_id = ChatlagWeb.ChatView.private_room(id1, id2)

        conn
        |> redirect(to: Routes.chat_path(conn, :chat, room_id))

      false ->
        conn
        |> redirect(to: "/")
    end
  end
end
