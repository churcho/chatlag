defmodule ChatlagWeb.ChatController do
  use ChatlagWeb, :controller


  def chat(conn, %{"id" => room_id}) do
    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Chat,
      session: %{room_id: room_id}
    )
  end
end
