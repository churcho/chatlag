defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias ChatlagWeb.Presence
  alias Chatlag.Chat
  alias Chatlag.Chat.Message

  alias Chatlag.RoomStatus

  alias Chatlag.Accounts
  alias Chatlag.Workers.UserState

  # alias ChatlagWeb.Router.Helpers, as: Routes
  @lo_topic "Chatlag-logout"

  def mount(session, socket) do
    # nodes = [node()]

    # # Create the schema
    # Memento.stop()
    # Memento.Schema.create(nodes)
    rid = String.to_integer(session.room_id)
    uid = session.user_id

    Memento.start()

    if connected?(socket) do
      Chat.subscribe(topic(session.room_id))
      Chat.subscribe(@lo_topic)
      Chat.subscribe("msg_#{uid}")
    end

    room_start()

    room = Chat.get_room!(session.room_id)

    addUserToRoom(session.user_id, session.room_id)

    user = Accounts.get_user!(uid)

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

    if room.is_private do
      [[_, u1, u2]] = Regex.scan(~r/room_(\d+)_(\d+)/, room.title)
      u1 = String.to_integer(u1)
      u2 = String.to_integer(u2)
      user1 = Accounts.get_user!(u1)
      user2 = Accounts.get_user!(u2)

      UserState.add_user(%{
        user_id: u1,
        room_id: rid,
        private: room.is_private,
        nickname: user1.nickname,
        party_id: user2.id,
        party: user2.nickname
      })

      # UserState.add_user(%{
      #   user_id: u2,
      #   room_id: rid,
      #   private: room.is_private,
      #   nickname: user2.nickname,
      #   party: user1.nickname
      # })
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

    display = get_state(utopic(session.user_id))

    socket = fetch(socket, session.room_id, session.user_id, display)
    {:ok, assign(socket, %{is_private: room.is_private, party_id: party_id})}
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id, display \\ "chat") do
    in_room = 1

    users = get_room_users(socket)

    # push_msgs = [];

    privates = UserState.my_private_chats(user_id)

    [rid] = UserState.my_last_room(user_id)

    assign(socket, %{
      display: display,
      max_id: 100,
      privates: 0,
      msgmsg: "",
      users: users,
      private_rooms: privates,
      room: Chatlag.Chat.get_room!(room_id),
      users_in_room: in_room,
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

  def handle_event("change_room", room_id, socket) do
    {:noreply, fetch(socket, room_id, get_user(socket), "chat")}
  end

  def handle_event("close_room", room_id, socket) do
    UserState.close_private_room(room_id)

    user_id = get_user(socket)

    privates = UserState.my_private_chats(user_id)

    {:noreply, assign(socket, private_rooms: privates, display: "privates")}
  end

  # ===========================================================================
  # def handle_event("send_message", %{"message" => params}, socket) do
  # ===========================================================================
  def handle_event("send_message", %{"message" => params}, socket) do
    case Chat.create_message(params) do
      {:ok, message} ->
        if is_room_private(socket) do
          party_id = get_party_id(socket)

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

    IO.puts("if #{me} == #{user_id} and #{room_id} != #{get_room_id(socket)}")

    rid = String.to_integer(get_room_id(socket))

    if me == user_id && room_id != rid do
      {:noreply, assign(socket, %{msgmsg: ""})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show-members", _params, socket) do
    [rid] = UserState.my_last_room(get_user(socket))

    privates = UserState.all_rooms(rid)

    {:noreply, assign(socket, last_room_id: rid, private_rooms: privates, display: "members")}
  end

  # for debug only 
  def handle_event("show-whoin", _params, socket) do
    users =
      Presence.list(topic(get_room_id(socket)))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    IO.inspect(users, label: "****** Users *******")

    uu = Memento.transaction!(fn -> Memento.Query.all(RoomStatus) end)

    IO.inspect(uu, label: "****** UU *******")
    users = get_room_users(socket)

    IO.inspect(users, label: "****** Users *******")

    {:noreply, socket}
  end

  def handle_event("show-privates", _params, socket) do
    uid = get_user(socket)
    [rid] = UserState.my_last_room(get_user(socket))

    privates = UserState.my_private_chats(uid)

    {:noreply, assign(socket, last_room_id: rid, private_rooms: privates, display: "privates")}
  end

  def handle_event("show-chat", _params, socket) do
    {:noreply, assign(socket, display: "chat")}
  end

  def handle_event("private_room", %{"message" => params}, socket) do
    user_id = params["user_id"]
    me = params["me"]

    room_id = ChatlagWeb.ChatView.private_room(me, user_id)
    Chat.subscribe(topic(room_id))
    {:noreply, fetch(socket, room_id, get_user(socket), "chat")}
  end

  @spec handle_info(
          {Chatlag.Chat, [...], any} | %{event: <<_::104>>, payload: any},
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, any}
  def handle_info({Chat, [:message, _event_type], _message}, socket) do
    {:noreply, fetch(socket, get_room_id(socket), get_user(socket), get_room_display(socket))}
  end

  def handle_info({:user_logedout, user_id}, socket) do
    me = get_user(socket)

    if me == user_id do
      {:stop, socket}
    else
      {:noreply, socket}
    end
  end

  # ========================================================================================
  #                  presence_diff
  # ========================================================================================
  def handle_info(
        %{event: "presence_diff", payload: payload},
        socket
      ) do
    users = get_room_users(socket)
    me = get_user(socket)
    IO.inspect(payload, label: "***[#{me}]*** payload *******")
    IO.inspect(users, label: "***[#{me}]*** Users *******")
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

  defp get_party_id(socket) do
    socket.assigns
    |> Map.get(:party_id)
  end

  defp get_room_id(socket) do
    socket.assigns
    |> Map.get(:room_id)
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
      topic(room_id),
      user_id,
      %{
        nickname: user.nickname,
        user_id: user_id,
        room_id: room_id
      }
    )
  end

  defp room_start do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  defp add(topic) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, topic, "chat")
    end)
  end

  defp get_state(topic) do
    stt =
      Agent.get(__MODULE__, fn state ->
        Map.get(state, topic)
      end)

    if stt == nil do
      add(topic)
    end
  end

  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end

  defp utopic(uid) do
    "ustate_#{uid}"
  end
end
