defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias ChatlagWeb.Presence
  alias Chatlag.Chat
  alias Chatlag.Chat.Message

  alias Chatlag.Accounts
  alias Chatlag.Workers.UserState

  # alias ChatlagWeb.Router.Helpers, as: Routes

  def mount(session, socket) do
    if connected?(socket), do: Chat.subscribe(topic(session.room_id))

    room = Chat.get_room!(session.room_id)
    addUserToRoom(session.user_id, session.room_id)

    UserState.add_user(%{uid: session.user_id, room_id: session.room_id, private: room.is_private})

    # for u <- Accounts.list_users() do
    #   addUserToRoom(u.id, session.room_id)
    # end

    {:ok, fetch(socket, session.room_id, session.user_id)}
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id, display \\ "chat") do
    in_room = 1

    users = get_room_users(socket)

    assign(socket, %{
      display: display,
      max_id: 100,
      privates: 0,
      users: users,
      room: Chatlag.Chat.get_room!(room_id),
      users_in_room: in_room,
      room_id: room_id,
      user_id: user_id,
      room_url: "/chat/#{room_id}",
      messages: Chat.list_messagese(room_id),
      changeset: Chat.change_message(%Message{user_id: user_id, room_id: room_id})
    })
  end

  def handle_event("validate", %{"message" => params}, socket) do
    changeset =
      %Message{}
      |> Chat.change_message(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("send_message", %{"message" => params}, socket) do
    case Chat.create_message(params) do
      {:ok, message} ->
        {:noreply, fetch(socket, message.room_id, get_user(socket), get_room_display(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("add-user", _params, socket) do
    next_id = get_next_id(socket)
    addUserToRoom(next_id, get_room_id(socket))

    {:noreply, assign(socket, max_id: next_id + 1)}
  end

  def handle_event("show-members", _params, socket) do
    {:noreply, assign(socket, display: "members")}
  end

  def handle_event("show-privates", _params, socket) do
    privates = [%{room: 123}, %{room: 125}]
    {:noreply, assign(socket, private_rooms: privates, display: "privates")}
  end

  def handle_event("show-chat", _params, socket) do
    {:noreply, assign(socket, display: "chat")}
  end

  def handle_event("private_room", %{"message" => params}, socket) do
    uid = params["uid"]
    me = params["me"]

    room_id = ChatlagWeb.ChatView.private_room(me, uid)

    Chat.subscribe(topic(room_id))
    {:noreply, fetch(socket, room_id, get_user(socket), "chat")}
  end

  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    {:noreply, fetch(socket, get_room_id(socket), get_user(socket), get_room_display(socket))}
  end

  def handle_info(
        %{event: "presence_diff", payload: _payload},
        socket
      ) do
    users =
      Presence.list(topic(get_room_id(socket)))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    {:noreply, assign(socket, users: users, users_in_room: Enum.count(users))}
  end

  defp get_room_users(socket) do
    Presence.list(topic(get_room_id(socket)))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)
  end

  defp get_user(socket) do
    socket.assigns
    |> Map.get(:user_id)
  end

  defp get_next_id(socket) do
    socket.assigns
    |> Map.get(:max_id)
  end

  defp get_room_id(socket) do
    socket.assigns
    |> Map.get(:room_id)
  end

  defp get_room_display(socket) do
    socket.assigns
    |> Map.get(:display)
  end

  defp addUserToRoom(user_id, room_id) do
    user = Accounts.get_user!(user_id)

    Presence.track(
      self(),
      topic(room_id),
      user_id,
      %{
        nickname: user.nickname,
        user_id: user_id,
        room_id: room_id
      }
    )
  end

  defp topic(room_id) do
    "Chatlag:#{room_id}"
  end
end
