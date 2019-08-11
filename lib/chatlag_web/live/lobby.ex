defmodule ChatlagWeb.Live.Lobby do
  use Phoenix.LiveView
  import Ecto.Query

  alias Chatlag.Repo

  alias Chatlag.Chat.Room
  alias Chatlag.Chat

  # alias ChatlagWeb.Presence

  def mount(_session, socket) do
    # |> where(on_front: true)
    all_rooms = Repo.all(Room)

    if connected?(socket) do
      Enum.each(all_rooms, fn room ->
        Chat.subscribe(topic(room.id))
      end)
    end

    {:ok, fetch(socket)}
  end

  def fetch(socket) do
    assign(socket, %{
      top_rooms:
        Repo.all(from(r in Room, select: %{id: r.id, title: r.title, slogen: r.slogen}, where: r.on_front == true)),
      rest_rooms:
        Repo.all(from(r in Room, select: %{id: r.id, title: r.title, slogen: r.slogen}, where: r.on_front == false))
    })
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("lobby.html", assigns)
  end

  def handle_info(
        %{event: "presence_diff", payload: payload},
        socket
      ) do
    # users =
    #   Presence.list(topic(get_room_id(socket)))
    #   |> Enum.map(fn {_user_id, data} ->
    #     data[:metas]
    #     |> List.first()
    #   end)

    IO.inspect(socket, label: "****Event all")
    IO.inspect(payload, label: "****Event all")

    {:noreply, socket}
  end

  defp topic(room_id) do
    "Chatlag:#{room_id}"
  end
end