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

    assign(socket, %{
      top_rooms:
        Repo.all(
          from(r in Room,
            select: %{id: r.id, title: r.title, slogen: r.slogen},
            where: r.on_front == true,
            where: r.is_private == false,
            order_by: r.id
          )
        ),
      rest_rooms: rest_rooms
    })
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("lobby.html", assigns)
  end

  def handle_info(
        %{event: "presence_diff", payload: _payload},
        socket
      ) do
    # users =
    #   Presence.list(topic(get_room_id(socket)))
    #   |> Enum.map(fn {_user_id, data} ->
    #     data[:metas]
    #     |> List.first()
    #   end)

    {:noreply, socket}
  end

  defp topic(room_id) do
    "Chatlag:#{room_id}"
  end
end
