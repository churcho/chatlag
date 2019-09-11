defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView
  alias ChatlagWeb.Presence
  alias Chatlag.{Users, Chat, PrivateMsg}
  alias Chatlag.Chat.Message

  alias Chatlag.Emails.ContactForm

  # alias ChatlagWeb.Router.Helpers, as: Routes
  # @lo_topic "Chatlag-logout"

  @all_users_topic "chatlag"
  @payload_topic "chatlag-payload"
  def mount(session, socket) do
    # ==================================================

    room_id = String.to_integer(session.room_id)
    user_id = session.user_id

    if connected?(socket) do
      addUserToRoom(user_id, room_id)
      Chat.subscribe(@payload_topic)
      Chat.subscribe("msg_#{user_id}")
      Chat.subscribe(topic(room_id))
    end

    socket =
      assign(socket, %{
        privates: 0,
        contact_cs: ContactForm.changeset(),
        reply_to: 0
      })

    {:ok, fetch(socket, room_id, user_id)}
  end

  # ======================================================================================================================================================

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

    display = get_display(socket, display)
    party_id = get_party_id(room_id, user_id)

    if party_id != nil && display == "chat" do
      PrivateMsg.sub_private(party_id, room_id, user_id)
    end

    assign(socket, %{
      users_in_room: get_users_in_room(last_room_id, user_id),
      privates: PrivateMsg.private_count(user_id),
      privates_list: PrivateMsg.privates_list(user_id),
      user_id: user_id,
      room_id: room_id,
      party_id: party_id,
      last_room_id: last_room_id,
      room_url: "/chat/#{last_room_id}",
      is_private: room.is_private,
      display: get_display(socket, display),
      users: get_room_users(last_room_id, user_id),
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

  def handle_event("msg_reply", params, socket) do
    reply_to = String.to_integer(params)

    me = get_user_id(socket)
    rid = get_room_id(socket)

    socket = fetch(socket, rid, me)

    {:noreply, assign(socket, reply_to: reply_to)}
  end

  # ===========================================================================
  # def handle_event(send_message, %{"message" => params}, socket) do
  # ===========================================================================
  def handle_event("send_message", %{"message" => params}, socket) do
    user_id = String.to_integer(params["user_id"])
    room_id = String.to_integer(params["room_id"])
    content = params["content"]

    len = content |> String.trim() |> String.length()
    party_id = get_party_id(room_id, user_id)

    isBlocked =
      case party_id do
        nil -> false
        _ -> PrivateMsg.is_blocked(user_id, party_id)
      end

    if len > 0 && !isBlocked do
      case Chat.create_message(params) do
        {:ok, _message} ->
          if party_id = get_party_id(room_id, user_id) do
            PrivateMsg.add_private(party_id, room_id, user_id)
            PrivateMsg.unblock_user(user_id, party_id)
            # inform me about this private chat too
            PrivateMsg.add_private(user_id, room_id, party_id)

            Phoenix.PubSub.broadcast(
              Chatlag.PubSub,
              "msg_#{party_id}",
              {[:push_msg, party_id, room_id, user_id], ""}
            )
          end

          socket = fetch(socket, room_id, user_id)
          {:noreply, assign(socket, reply_to: 0)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end

    socket = fetch(socket, room_id, user_id)
    {:noreply, assign(socket, reply_to: 0)}
  end

  # ===================================================================
  # def handle_info({[:push_msg, party_id, room_id, user_id], _message}, socket)
  # ===================================================================
  def handle_info({[:push_msg, party_id, room_id, user_id], _message}, socket) do
    me = get_user_id(socket)
    rid = get_room_id(socket)

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
  def handle_event("change_room", _room_id, socket) do
    # ===================================================================
    # user_id = get_user_id(socket)
    # room_id = String.to_integer(room_id)

    {:noreply, assign(socket, display: "chat")}
    # {:noreply, fetch(socket, room_id, user_id, "chat")}
  end

  def handle_event("show_privates", _params, socket) do
    # room_id = get_room_id(socket)
    # user_id = get_user_id(socket)

    {:noreply, assign(socket, display: "privates")}
    # {:noreply, fetch(socket, room_id, user_id, "privates")}
  end

  # ===================================================================
  def handle_event("ban_party", party_id, socket) do
    room_id = get_room_id(socket)
    user_id = get_user_id(socket)
    party_id = String.to_integer(party_id)
    PrivateMsg.block_user(user_id, party_id)
    {:noreply, fetch(socket, room_id, user_id, "members")}
  end

  # ===================================================================
  def handle_event("unban_party", party_id, socket) do
    room_id = get_room_id(socket)
    user_id = get_user_id(socket)
    party_id = String.to_integer(party_id)
    PrivateMsg.unblock_user(user_id, party_id)
    {:noreply, fetch(socket, room_id, user_id, "members")}
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
    me = get_user_id(socket)
    room_id = ChatlagWeb.ChatView.private_room(user_id, me)
    PrivateMsg.close_private_room(room_id)
    PrivateMsg.close_private_room(user_id, me)

    {:noreply, fetch(socket, room_id, me)}
  end

  def handle_event("close_reply", _params, socket) do
    # user_id = get_user_id(socket)
    # room_id = get_room_id(socket)

    {:noreply, assign(socket, reply_to: 0)}
    # {:noreply, fetch(socket, room_id, user_id)}
  end

  def handle_event("contact_form", _params, socket) do
    user_id = get_user_id(socket)
    room_id = get_room_id(socket)

    {:noreply, fetch(socket, room_id, user_id, "letter")}
  end

  def handle_event("send_letter", %{"contact_form" => params}, socket) do
    user_id = get_user_id(socket)
    room_id = get_room_id(socket)

    changeset = ContactForm.changeset(params)

    case ContactForm.send(changeset) do
      {:ok, contact_form} ->
        {:noreply, fetch(assign(socket, contact_cs: changeset), room_id, user_id)}

      {:error, changeset} ->
        {:noreply, fetch(assign(socket, contact_cs: changeset), room_id, user_id)}
    end
  end

  def handle_event("show_whoin", _params, socket) do
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
    user = Users.get_user!(user_id)

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
        is_blocked: false,
        nickname: user.nickname,
        age: user.age,
        user_id: user_id,
        room_id: room_id
      }
    )
  end

  def handle_info({:room_user_changed}, socket) do
    user_id =
      socket.assigns
      |> Map.get(:user_id)

    room_id =
      socket.assigns
      |> Map.get(:room_id)

    {:noreply, fetch(socket, room_id, user_id)}
  end

  # ========================================================================================
  #                  presence_diff
  # ========================================================================================
  def handle_info(
        %{event: "presence_diff", payload: _payload},
        socket
      ) do
    Phoenix.PubSub.broadcast(
      Chatlag.PubSub,
      @payload_topic,
      {:room_user_changed}
    )

    user_id = get_user_id(socket)
    room_id = get_room_id(socket)

    {:noreply,
     assign(socket,
       users: get_room_users(room_id, user_id),
       users_in_room: get_users_in_room(room_id, user_id)
     )}
  end

  defp get_room_users(room_id, me) do
    all_users =
      Presence.list(topic(room_id))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    Enum.map(all_users, fn elem ->
      blk = PrivateMsg.is_2w_blocked(elem.user_id, me)
      Map.put(elem, :is_blocked, blk)
    end)
  end

  def get_users_in_room(room_id, user_id) do
    get_room_users(room_id, user_id)
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

  # ========================
  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end
end
