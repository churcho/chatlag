defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias Chatlag.Chat
  alias Chatlag.Chat.Message

  def mount(_session, socket) do
    if connected?(socket), do: Chat.subscribe()
    {:ok, fetch(socket)}
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, user_id \\ nil) do
    assign(socket, %{
      user_id: user_id,
      messages: Chat.list_messagese(),
      changeset: Chat.change_message(%Message{user_id: 2, room_id: 1})
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
        {:noreply, fetch(socket, message.id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    {:noreply, fetch(socket, get_user_name(socket))}
  end

  defp get_user_name(socket) do
    socket.assigns
    |> Map.get(:user_id)
  end
end
