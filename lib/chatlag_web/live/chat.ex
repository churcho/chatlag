defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias ChatlagWeb.Presence
  alias Chatlag.Chat
  alias Chatlag.Chat.Message
  alias Chatlag.PrivateMsg

  alias Chatlag.RoomStatus
  alias Chatlag.PrivateStatus

  alias Chatlag.Accounts
  alias Chatlag.Workers.UserState

  # alias ChatlagWeb.Router.Helpers, as: Routes
  @lo_topic "Chatlag-logout"

  def mount(session, socket) do
    # ==================================================
    rid = String.to_integer(session.room_id)
    uid = session.user_id
    room = Chat.get_room!(session.room_id)

    party_id =
      case room.is_private do
        true ->
          [[_, u1, u2]] = Regex.scan(~r/room_(\d+)_(\d+)/, room.title)
          u1 = String.to_integer(u1)
          u2 = String.to_integer(u2)

          if uid == u1 do
            u2
          else
            u1
          end

        false ->
          nil
      end

    addUserToRoom(session.user_id, session.room_id)
    user = Accounts.get_user!(uid)

    if connected?(socket) do
      Chat.subscribe(topic(session.room_id))
      Chat.subscribe(@lo_topic)
      Chat.subscribe("msg_#{uid}")
      Chat.subscribe("prvt_#{uid}")

      publish_user_updated()

      if room.is_private do
        [[_, u1, u2]] = Regex.scan(~r/room_(\d+)_(\d+)/, room.title)
        u1 = String.to_integer(u1)
        u2 = String.to_integer(u2)
        user1 = Accounts.get_user!(u1)
        user2 = Accounts.get_user!(u2)

        # update msg count
        PrivateMsg.sub_private(uid, rid)

        UserState.add_user(%{
          user_id: u1,
          room_id: rid,
          private: room.is_private,
          nickname: user1.nickname,
          party_id: user2.id,
          party: user2.nickname
        })
      else
        u = %{
          user_id: uid,
          room_id: rid,
          private: room.is_private,
          party_id: nil,
          party: nil,
          nickname: user.nickname
        }

        UserState.add_user(u)
      end
    end

    socket = fetch(socket, session.room_id, session.user_id)
    nickname = user.nickname

    {:ok,
     assign(socket, %{
       is_private: room.is_private,
       party_id: party_id,
       party_nickname: party_nickname(party_id),
       nickname: nickname,
       msgmsg: ""
     })}
  end

  defp party_nickname(uid) do
    case uid do
      nil ->
        ""
      _ ->
        user = Accounts.get_user!(uid)
        user.nickname
    end
  end
  # ======================================================================================================================================================

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id, display \\ "chat") do
    in_room = users_in_room(room_id)

    users = get_room_users(socket)

    privates = UserState.my_private_chats(user_id)

    [rid] = UserState.my_last_room(user_id)

    assign(socket, %{
      display: display,
      max_id: 100,
      users: users,
      private_rooms: privates,
      room: Chatlag.Chat.get_room!(room_id),
      users_in_room: in_room,
      privates: PrivateMsg.private_count(user_id),
      room_id: room_id,
      last_room_id: rid,
      user_id: user_id,
      room_url: "/chat/#{room_id}",
      messages: Chat.list_messagese(room_id, 100),
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

  # ===================================================================
  def handle_event("change_room", room_id, socket) do
    # ===================================================================
    me = get_user(socket)
    addUserToRoom(me, room_id)

    rid = String.to_integer(room_id)

    PrivateMsg.sub_private(me, rid)

    privates = PrivateMsg.private_count(me)

    # IO.puts("Change room [#{privates} [#{me}] #{room_id}")
    socket = assign(socket, privates: privates)

    {:noreply, fetch(socket, room_id, get_user(socket), "chat")}
  end

  def handle_event("close_room", room_id, socket) do
    UserState.close_private_room(room_id)

    user_id = get_user(socket)

    privates = UserState.my_private_chats(user_id)

    {:noreply, assign(socket, private_rooms: privates, display: "privates")}
  end

  # ===========================================================================
  # def handle_event(send_message, %{"message" => params}, socket) do
  # ===========================================================================
  def handle_event("send_message", %{"message" => params}, socket) do
    case Chat.create_message(params) do
      {:ok, message} ->
        if is_room_private(socket) do
          party_id = get_party_id(socket)
          # me = get_user(socket)
          IO.puts("Send private msg to #{party_id} in room #{message.room_id}")
          ## add me as have private room
          # add_private_to(me, message.room_id, get_party_nickname(socket))
          ## Update party
          add_private_to(party_id, message.room_id, get_nickname(socket))

          Phoenix.PubSub.broadcast(
            Chatlag.PubSub,
            "msg_#{party_id}",
            {[:push_msg, message.room_id, party_id], "you have private call"}
          )
        end

        {:noreply, fetch(socket, message.room_id, get_user(socket), get_room_display(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # ===========================================================================
  # def handle_info({[:push_msg, room_id, user_id], message}, socket) do
  # ===========================================================================

  def handle_info({[:push_msg, room_id, user_id], _message}, socket) do
    me = get_user(socket)

    rid = String.to_integer(get_room_id(socket))

    if me == user_id and rid == room_id do
      IO.puts(" delete message if #{me} == #{user_id} and #{room_id} != #{get_room_id(socket)}")
    end

    if me == user_id do
      PrivateMsg.sub_private(user_id, rid)
      {:noreply, assign(socket, %{privates: PrivateMsg.private_count(user_id)})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_members", _params, socket) do
    [rid] = UserState.my_last_room(get_user(socket))

    privates = UserState.all_rooms(rid)

    {:noreply, assign(socket, last_room_id: rid, private_rooms: privates, display: "members")}
  end

  # for debug only
  def handle_event("show_whoin", _params, socket) do
    users =
      Presence.list(topic(get_room_id(socket)))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    IO.inspect(users, label: "****** Users *******")

    users = Presence.list("chatlag")

    IO.inspect(users, label: "****** 2users  *******")

    uu = Memento.transaction!(fn -> Memento.Query.all(RoomStatus) end)

    IO.inspect(uu, label: "****** UU *******")
    users = get_room_users(socket)

    IO.inspect(users, label: "****** Users *******")

    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, [])
      end)

    IO.inspect(res, label: "****** Privates *******")

    {:noreply, socket}
  end

  # =======================================================================================
  def handle_event("show_privates", _params, socket) do
    uid = get_user(socket)
    [rid] = UserState.my_last_room(get_user(socket))

    privates = PrivateMsg.privates(uid)

    # IO.inspect(privates, label: "+++++ Privates")

    {:noreply, assign(socket, last_room_id: rid, private_rooms: privates, display: "privates")}
  end

  def handle_event("show_chat", _params, socket) do
    {:noreply, assign(socket, display: "chat")}
  end

  def handle_event("private_room", %{"message" => params}, socket) do
    user_id = params["user_id"]
    me = params["me"]

    room_id = ChatlagWeb.ChatView.private_room(me, user_id)

    Chat.subscribe(topic(room_id))

    {:noreply, fetch(socket, room_id, get_user(socket), "chat")}
  end

  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    {:noreply, fetch(socket, get_room_id(socket), get_user(socket), get_room_display(socket))}
  end

  # ================================================================
  def handle_info({:user_logedout, user_id}, socket) do
    # ================================================================
    me = get_user(socket)

    if me == user_id do
      Phoenix.PubSub.broadcast(
        Chatlag.PubSub,
        "msg_#{me}",
        {[:push_msg, get_room_id(socket), me], "יצאתם מהמערכת"}
      )

      {:stop, socket}
    else
      {:noreply, socket}
    end
  end

  # ================================================================
  def handle_info({:private_msg, uid, rid}, socket) do
    # ================================================================
    me = get_user(socket)

    socket =
      if me == uid do
        msgs = PrivateMsg.private_count(uid)
        IO.puts("Getting private msg me: #{me} uid: #{uid} to room #{rid} - #{msgs}")
        assign(socket, %{privates: msgs})
      end

    {:noreply, socket}
  end

  # ========================================================================================
  #                  presence_diff
  # ========================================================================================
  def handle_info(
        %{event: "presence_diff", payload: _payload},
        socket
      ) do
    users = get_room_users(socket)
    {:noreply, assign(socket, users: users, users_in_room: Enum.count(users))}
  end

  defp publish_user_updated do
    Phoenix.PubSub.broadcast(Chatlag.PubSub, "users_updated", :user_updated)
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

  defp get_party_id(socket) do
    socket.assigns
    |> Map.get(:party_id)
  end

  defp get_room_id(socket) do
    socket.assigns
    |> Map.get(:room_id)
  end

  defp get_nickname(socket) do
    socket.assigns
    |> Map.get(:nickname)
  end
  defp get_party_nickname(socket) do
    socket.assigns
    |> Map.get(:party_nickname)
  end

  defp is_room_private(socket) do
    socket.assigns
    |> Map.get(:is_private)
  end

  defp get_room_display(socket) do
    socket.assigns
    |> Map.get(:display)
  end

  defp addUserToRoom(user_id, room_id) do
    user = Accounts.get_user!(user_id)

    Presence.track(
      self(),
      "chatlag",
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

  defp add_private_to(uid, rid, nickname) do
    PrivateMsg.add_private(uid, rid, nickname)

    Phoenix.PubSub.broadcast(Chatlag.PubSub, "prvt_#{uid}", {:private_msg, uid, rid})
  end

  defp users_in_room(rid) do
    users =
      Presence.list(topic(rid))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    Enum.count(users)
  end

  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end
end
