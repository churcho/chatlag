defmodule ChatlagWeb.ChatController do
  use ChatlagWeb, :controller
  alias Chatlag.Chat

  # //render(conn, "chat.html", bg_color: room.bg_color, url: ChatWeb.RoomView.get_bg_url(room), url_sm: ChatWeb.RoomView.get_bg_sm_url(room), room: room, layout: {ChatWeb.LayoutView, "room.html"})
  def chat(conn, %{"id" => room_id}) do
    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Chat,
      session: %{room_id: room_id}
    )
  end
end
