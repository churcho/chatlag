defmodule ChatlagWeb.Live.Lobby do
  use Phoenix.LiveView
  import Ecto.Query

  alias Chatlag.Repo

  alias Chatlag.Chat.Room

  alias Chatlag.RoomStatus

  @topic "users_updated"

  def mount(session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Chatlag.PubSub, @topic)
    end

    all_rooms =
      Repo.all(
        from(r in Room,
          select: %{id: r.id},
          where: r.is_private == false,
          order_by: r.id
        )
      )

    rooms_count =
      Enum.reduce(all_rooms, %{}, fn r, acc ->
        Map.put(acc, "room-#{r.id}", users_in_room(r.id))
      end)

    rooms =
      Repo.all(
        from(r in Room,
          select: %{id: r.id, title: r.title, slogen: r.slogen},
          where: r.on_front == false,
          where: r.is_private == false,
          order_by: r.id
        )
      )

    rest_rooms = Enum.chunk_every(rooms, 2)

    top_rooms =
      Repo.all(
        from(r in Room,
          select: %{id: r.id, title: r.title, slogen: r.slogen},
          where: r.on_front == true,
          where: r.is_private == false,
          order_by: r.id
        )
      )

    socket = assign(socket, %{current_user: session.current_user})
    {:ok, fetch(socket, top_rooms, rest_rooms, rooms_count)}
  end

  def fetch(socket, top_rooms, rest_rooms, rooms_count) do
    assign(socket, %{
      top_rooms: top_rooms,
      rest_rooms: rest_rooms,
      rooms_count: rooms_count
    })
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("lobby.html", assigns)
  end

  def handle_info(:user_updated, socket) do
    {:noreply, socket}
  end

  defp users_in_room(room_id) do
    q = [
      {:==, :room_id, room_id}
    ]

    users =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, q)
      end)

    Enum.count(users)
  end
end
