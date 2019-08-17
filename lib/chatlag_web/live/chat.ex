defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias ChatlagWeb.Presence
  alias Chatlag.Chat
  alias Chatlag.Chat.Message

  # alias ChatlagWeb.Router.Helpers, as: Routes

  def mount(session, socket) do
    if connected?(socket), do: Chat.subscribe(topic(session.room_id))

    addUserToRoom(session.user_id, session.room_id)

    {:ok, fetch(socket, session.room_id, session.user_id)}
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id) do
    in_room = 1
    all_u = 100

    assign(socket, %{
      display: "chat",
      max_id: 100,
      room: Chatlag.Chat.get_room!(room_id),
      all_users: all_u,
      users_in_room: in_room,
      room_id: room_id,
      user_id: user_id,
      # Routes.chat_path(socket, room_id),
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
        {:noreply, fetch(socket, message.room_id, get_user(socket))}

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

  def handle_event("show-chat", _params, socket) do

    {:noreply, assign(socket, display: "chat")}
  end

  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    {:noreply, fetch(socket, get_room_id(socket), get_user(socket))}
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

    {:noreply, assign(socket, users: users, all_users: 123, users_in_room: Enum.count(users))}
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

  defp addUserToRoom(user_id, room_id) do
    Presence.track(
      self(),
      topic(room_id),
      user_id,
      %{
        nickname: "heheh #{user_id}",
        user_id: user_id,
        room_id: room_id
      }
    )
  end

  defp topic(room_id) do
    "Chatlag:#{room_id}"
  end
end
