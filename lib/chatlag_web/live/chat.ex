defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias Chatlag.Chat
  alias Chatlag.Chat.Message

  def mount(session, socket) do
    if connected?(socket), do: Chat.subscribe(session.room_id)
    {:ok, fetch(socket, session.room_id, session.user_id)}
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id, users_in_room \\ 0) do
    assign(socket, %{
      room: Chatlag.Chat.get_room!(room_id),
      room_id: room_id,
      user_id: user_id,
      users_in_room: users_in_room,
      users: 120,
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
        {:noreply, fetch(socket, message.room_id, get_user(socket), get_users_in_room(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    {:noreply, fetch(socket, get_room_id(socket), get_user(socket), get_users_in_room(socket) + 1)}
  end

  defp get_user(socket) do
    socket.assigns
    |> Map.get(:user_id)
  end
  defp get_room_id(socket) do
    socket.assigns
    |> Map.get(:room_id)
  end

  defp get_users_in_room(socket) do
    socket.assigns
    |> Map.get(:users_in_room)
  end
end
