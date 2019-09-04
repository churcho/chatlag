defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView
  alias ChatlagWeb.Presence
  alias Chatlag.{Accounts, Chat, PrivateMsg}
  alias Chatlag.Chat.Message

  # alias ChatlagWeb.Router.Helpers, as: Routes
  # @lo_topic "Chatlag-logout"

  @all_users_topic "chatlag"
  def mount(session, socket) do
    # ==================================================

    room_id = String.to_integer(session.room_id)
    user_id = session.user_id

    if connected?(socket) do
      addUserToRoom(user_id, room_id)
      Chat.subscribe("msg_#{user_id}")
      Chat.subscribe(topic(room_id))
    else
      IO.inspect(session, label: "** ================== not Conected")
    end

    socket =
      assign(socket, %{
        privates: 0
      })

    {:ok, fetch(socket, room_id, user_id)}
  end

  # ======================================================================================================================================================

  defp get_party_id(room_id, user_id) do
    room = Chat.get_room!(room_id)

    case room.is_private do
      false ->
        nil

      true ->
        [[_, u1, u2]] = Regex.scan(~r/room_(\d+)_(\d+)/, room.title)
        u1 = String.to_integer(u1)
        u2 = String.to_integer(u2)

        if user_id == u1 do
          u2
        else
          u1
        end
    end
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id, display \\ nil) do
    room = Chat.get_room!(room_id)

    old_room = get_last_room_id(socket, room.id)

    last_room_id =
      if room.is_private do
        old_room
      else
        room.id
      end

    party_id = get_party_id(room_id, user_id)

    PrivateMsg.sub_private(party_id, room_id, user_id)

    assign(socket, %{
      users_in_room: get_users_in_room(last_room_id),
      privates: PrivateMsg.private_count(user_id),
      privates_list: PrivateMsg.privates_list(user_id),
      user_id: user_id,
      room_id: room_id,
      party_id: party_id,
      last_room_id: last_room_id,
      room_url: "/chat/#{last_room_id}",
      is_private: room.is_private,
      display: get_display(socket, display),
      users: get_room_users(last_room_id),
      messages: Chat.list_messagese(room_id, 100),
      changeset: Chat.change_message(%Message{user_id: user_id, room_id: room_id})
    })
  end

  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    user_id =
      socket.assigns
      |> Map.get(:user_id)

    room_id =
      socket.assigns
      |> Map.get(:room_id)

    {:noreply, fetch(socket, room_id, user_id)}
  end

  # ===========================================================================
  # def handle_event(send_message, %{"message" => params}, socket) do
  # ===========================================================================
  def handle_event("send_message", %{"message" => params}, socket) do
    user_id = String.to_integer(params["user_id"])
    room_id = String.to_integer(params["room_id"])
    content = params["content"]

    len = content |> String.trim() |> String.length()

    if len > 0 do
      case Chat.create_message(params) do
        {:ok, _message} ->
          if party_id = get_party_id(room_id, user_id) do
            Phoenix.PubSub.broadcast(
              Chatlag.PubSub,
              "msg_#{party_id}",
              {[:push_msg, party_id, room_id, user_id], ""}
            )

            PrivateMsg.add_private(party_id, room_id, user_id)
          end

          {:noreply, fetch(socket, room_id, user_id)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end

    {:noreply, fetch(socket, room_id, user_id)}
  end

  # ===================================================================
  # def handle_info({[:push_msg, party_id, room_id, user_id], _message}, socket)
  # ===================================================================
  def handle_info({[:push_msg, party_id, room_id, user_id], _message}, socket) do

    me = get_user_id(socket)
    rid = get_room_id(socket)

    IO.inspect("Push: #{party_id} #{room_id} #{user_id} I am #{me} in rid #{rid}")

    if me == user_id and rid == room_id do
      PrivateMsg.sub_private(user_id, room_id, party_id)
    end

    {:noreply, fetch(socket, rid, me)}
  end

  # ===================================================================
  def handle_event("show_members", _params, socket) do
    # ===================================================================
    room_id = get_room_id(socket)
    user_id = get_user_id(socket)

    {:noreply, fetch(socket, room_id, user_id, "members")}
  end

  # ===================================================================
  #  change back to main room
  # ===================================================================
  def handle_event("change_room", room_id, socket) do
    # ===================================================================
    room_id = String.to_integer(room_id)
    user_id = get_user_id(socket)

    {:noreply, fetch(socket, room_id, user_id, "chat")}
  end

  def handle_event("show_privates", _params, socket) do
    room_id = get_room_id(socket)
    user_id = get_user_id(socket)

    {:noreply, fetch(socket, room_id, user_id, "privates")}
  end

  # ===================================================================
  def handle_event("private_room", party_id, socket) do
    # ===================================================================
    party_id = String.to_integer(party_id)
    me = get_user_id(socket)
    room_id = ChatlagWeb.ChatView.private_room(party_id, me)
    Chat.subscribe(topic(room_id))

    {:noreply, fetch(socket, room_id, me, "chat")}
  end

  def handle_event("close_private_room", user_id, socket) do
    user_id = String.to_integer(user_id)
    IO.inspect(user_id, label: "close private room")
    me = get_user_id(socket)
    room_id = ChatlagWeb.ChatView.private_room(user_id, me)

    {:noreply, socket}
  end

  def handle_event("show_whoin", _params, socket) do
    IO.inspect(get_room_users(get_last_room_id(socket)))

    users =
      Presence.list(@all_users_topic)
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    IO.inspect(socket)
    IO.inspect(PrivateMsg.all_privates())
    IO.inspect(users)
    {:noreply, socket}
  end

  # ===========================================================================
  # defp addUserToRoom(user_id, room_id) do
  # ===========================================================================
  defp addUserToRoom(user_id, room_id) do
    user = Accounts.get_user!(user_id)

    Presence.track(
      self(),
      @all_users_topic,
      user.nickname,
      %{
        user_id: user_id,
        nickname: user.nickname
      }
    )

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

  # ========================================================================================
  #                  presence_diff
  # ========================================================================================
  def handle_info(
        %{event: "presence_diff", payload: _payload},
        socket
      ) do
    room_id = get_room_id(socket)

    {:noreply,
     assign(socket, users: get_room_users(room_id), users_in_room: get_users_in_room(room_id))}
  end

  defp get_room_users(room_id) do
    Presence.list(topic(room_id))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)
  end

  def get_users_in_room(room_id) do
    get_room_users(room_id)
    |> Enum.count()
  end

  defp get_user_id(socket) do
    socket.assigns
    |> Map.get(:user_id)
  end

  defp get_room_id(socket) do
    socket.assigns
    |> Map.get(:room_id)
  end

  defp get_display(socket, dsply) do
    display =
      socket.assigns
      |> Map.get(:display)

    display =
      case dsply do
        nil -> display
        _ -> dsply
      end

    case display do
      nil -> "chat"
      _ -> display
    end
  end

  defp get_last_room_id(socket, id \\ nil) do
    case rid = socket.assigns |> Map.get(:last_room_id) do
      nil ->
        id

      _ ->
        rid
    end
  end

  # ========================
  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end
end
