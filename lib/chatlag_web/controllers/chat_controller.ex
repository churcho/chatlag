defmodule ChatlagWeb.ChatController do
  use ChatlagWeb, :controller

  def chat(conn, _params) do
    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Chat,
      session: %{}
    )
  end
end
