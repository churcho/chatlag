defmodule ChatlagWeb.Live.Frontpage do
  use Phoenix.LiveView
  alias ChatlagWeb.Presence
  alias Chatlag.Chat

  import Ecto.Query

  alias Chatlag.Repo

  alias Chatlag.Chat.Room

  @payload_topic "chatlag-payload"

  def mount(session, socket) do
    user_id = session.user_id

    Chat.subscribe(@payload_topic)
    if connected?(socket) do

      IO.inspect(session, label: "** ================== Conected")
    end

    {:ok, fetch(socket, user_id)}
  end

  def render(assigns) do
    ChatlagWeb.FrontpageView.render("front.html", assigns)
  end

  def fetch(socket, user_id) do
    # ================================================================ Fetch
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
        Map.put(acc, "room-#{r.id}", get_users_in_room(r.id))
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

    active = Repo.all(from(r in Room, select: %{id: r.id}, where: r.is_private == false))

    num_of_rooms = active |> Enum.count()

    num_in_chats = Enum.reduce(rooms_count, 0, fn {_k, v}, acc -> v + acc end)
    active_chats = Enum.filter(rooms_count, fn {_, b} = _x -> b > 0 end) |> Enum.count()

    assign(socket,
      user_id: user_id,
      top_rooms: top_rooms,
      rest_rooms: rest_rooms,
      rooms_count: rooms_count,
      active_chats: active_chats,
      num_in_chats: num_in_chats,
      num_of_rooms: num_of_rooms
    )
  end

  def handle_info({:room_user_changed}, socket) do
    user_id = get_user_id(socket)
    IO.inspect("#{user_id}", label: "************ room_user_changed")
    {:noreply, fetch(socket, user_id)}
  end

  def handle_info(:room_user_changed, socket) do
    IO.inspect("Changed++++++++++++++++++")
    {:noreply, socket}
  end

  # ========================================================================================
  #                  presence_diff
  # ========================================================================================
  def handle_info(
        %{event: "presence_diff", payload: payload},
        socket
      ) do
    IO.inspect(payload)
    {:noreply, fetch(socket, user_id: get_user_id(socket))}
  end

  defp get_room_users(room_id) do
    Presence.list(topic(room_id))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)
  end

  defp get_users_in_room(room_id) do
    get_room_users(room_id)
    |> Enum.count()
  end

  defp get_user_id(socket) do
    socket.assigns
    |> Map.get(:user_id)
  end

  # ========================
  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end
end
