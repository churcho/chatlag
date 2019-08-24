defmodule ChatlagWeb.Live.Chat do
  use Phoenix.LiveView

  alias ChatlagWeb.Presence
  alias Chatlag.Chat
  alias Chatlag.Chat.Message

  alias Chatlag.Accounts
  alias Chatlag.Workers.UserState

  # alias ChatlagWeb.Router.Helpers, as: Routes

  def mount(session, socket) do
    if connected?(socket) do
      Chat.subscribe(topic(session.room_id))
    end

    room_start()

    room = Chat.get_room!(session.room_id)
    addUserToRoom(session.user_id, session.room_id)

    rid = String.to_integer(session.room_id)
    uid = session.user_id

    user = Accounts.get_user!(uid)

    if room.is_private do
      [[_, u1, u2]] = Regex.scan(~r/room_(\d+)_(\d+)/, room.title)
      u1 = String.to_integer(u1)
      u2 = String.to_integer(u2)
      user1 = Accounts.get_user!(u1)
      user2 = Accounts.get_user!(u2)

      UserState.add_user(%{
        uid: u1,
        room_id: rid,
        private: room.is_private,
        nickname: user1.nickname,
        party: user2.nickname
      })

      UserState.add_user(%{
        uid: u2,
        room_id: rid,
        private: room.is_private,
        nickname: user2.nickname,
        party: user1.nickname
      })
    else
      u = %{
        uid: uid,
        room_id: rid,
        private: room.is_private,
        party: nil,
        nickname: user.nickname
      }

      UserState.add_user(u)
    end

    display = get_state(utopic(session.user_id))

    # for u <- Accounts.list_users() do
    #   addUserToRoom(u.id, session.room_id)
    # end

    {:ok, fetch(socket, session.room_id, session.user_id, display)}
  end

  def render(assigns) do
    ChatlagWeb.ChatView.render("chat.html", assigns)
  end

  def fetch(socket, room_id, user_id, display \\ "chat") do
    in_room = 1

    users = get_room_users(socket)

    privates =
      for r <- UserState.all_rooms(user_id), r.uid == user_id do
        r
      end

    assign(socket, %{
      display: display,
      max_id: 100,
      privates: 0,
      users: users,
      private_rooms: privates,
      room: Chatlag.Chat.get_room!(room_id),
      users_in_room: in_room,
      room_id: room_id,
      user_id: user_id,
      room_url: "/chat/#{room_id}",
      messages: Chat.list_messagese(room_id, 10),
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
    {:noreply, fetch(socket, room_id, get_user(socket))}
  end

  def handle_event("close_room", _room_id, socket) do
    {:noreply, socket}
  end

  # def handle_event("master_room", "", socket) do
  #   uid = get_user(socket)
  #   room_id = 43
  #   privates =
  #     for r <- UserState.all_rooms(uid), r.uid == uid, !r.party do
  #       r
  #     end

  #     # IO.inspect(privates, label: "***master")
  #   {:noreply, fetch(socket, room_id, get_user(socket))}
  # end

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
    uid = get_user(socket)
    rid = get_room_id(socket)
    IO.puts("room: #{rid}")

    privates =
      for r <- UserState.all_rooms(uid) do
        r
      end

    {:noreply, assign(socket, users: privates, display: "members")}
  end

  def handle_event("show-privates", _params, socket) do
    uid = get_user(socket)

    # TBD
    privates =
      for r <- UserState.all_rooms(uid), r.uid == uid do
        r
      end

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

  defp set_state(topic, pos) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, topic, pos)
    end)
  end

  defp utopic(uid) do
    "ustate_#{uid}"
  end
end
