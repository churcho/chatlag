defmodule Chatlag.Workers.UserState do
  use GenServer

  alias Chatlag.RoomStatus
  alias Chatlag.Repo

  alias Chatlag.Chat.Room
  alias ChatlagWeb.Presence

  @lo_topic "Chatlag-logout"

  # API
  def start_link(_state) do
    Chatlag.PrivateMsg.reset
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def user_logedin(user_id) do
    GenServer.cast(__MODULE__, {:user_logedin, user_id})
  end

  def user_logout(user_id) do
    GenServer.cast(__MODULE__, {:user_logout, user_id})
  end

  def add_user(user) do
    GenServer.cast(__MODULE__, {:add_user, user})
  end

  def del_user(user) do
    ########### TODO
    GenServer.cast(__MODULE__, {:del_user, user})
  end

  def all_rooms(user) do
    GenServer.call(__MODULE__, {:all_rooms, user})
  end

  def my_last_room(user_id) do
    GenServer.call(__MODULE__, {:my_last_room, user_id})
  end

  def my_private_chats(user_id) do
    GenServer.call(__MODULE__, {:my_private_chats, user_id})
  end

  def close_private_room(room_id) do
    GenServer.call(__MODULE__, {:close_private_room, room_id})
  end

  # CALLBACKS
  def init(state) do
    {:ok, state}
  end

  def handle_call({:close_private_room, room_id}, _from, state) do
    room_id = String.to_integer(room_id)

    query = [
      {:==, :room_id, room_id},
      {:==, :private, true}
    ]

    all =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, query)
      end)

    for r <- all do
      Memento.transaction!(fn ->
        Memento.Query.delete(RoomStatus, r.id)
      end)
    end

    {:reply, state, state}
  end

  def handle_call({:my_private_chats, user_id}, _from, _state) do
    q1 = [
      {:==, :user_id, user_id},
      {:==, :private, true}
    ]

    q2 = [
      {:==, :party_id, user_id},
      {:==, :private, true}
    ]

    a1 =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, q1)
      end)

    a2 =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, q2)
      end)

    all = Enum.concat(a1, a2)

    newRecs = []

    newRecs =
      Enum.map(all, fn r ->
        Enum.into(newRecs, %{
          nickname: r.nickname,
          party: r.party,
          party_id: r.party_id,
          private: r.private,
          room_id: r.room_id,
          user_id: r.user_id
        })
      end)

    {:reply, newRecs, newRecs}
  end

  def handle_call({:my_last_room, user_id}, _from, state) do
    query = [
      {:==, :user_id, user_id},
      {:!=, :private, true}
    ]

    all =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, query)
      end)

    room =
      case Enum.count(all) do
        0 ->
          nil

        _ ->
          res = Enum.at(all, 0)
          res.room_id
      end

    res = [room]

    {:reply, res, state}
  end

  # ============================================================
  def handle_call({:all_rooms, room_id}, _from, _state) do
    guards =
      case room_id do
        nil ->
          []

        _ ->
          # String.to_integer(room_id)
          rid = room_id

          [
            {:==, :room_id, rid}
          ]
      end

    all =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, guards)
      end)

    newRecs = []

    newRecs =
      Enum.map(all, fn r ->
        Enum.into(newRecs, %{
          nickname: r.nickname,
          party_id: r.party_id,
          party: r.party,
          private: r.private,
          room_id: r.room_id,
          user_id: r.user_id
        })
      end)

    {:reply, newRecs, newRecs}
  end

  def handle_cast({:user_logedin, _user_id}, state) do
    {:noreply, state}
  end

  # ============================================================
  def handle_cast({:add_user, user}, state) do
    uu = user_exists(user)

    state =
      case Enum.count(uu) do
        0 ->
          Memento.transaction!(fn ->
            Memento.Query.write(%RoomStatus{
              room_id: user.room_id,
              user_id: user.user_id,
              nickname: user.nickname,
              private: user.private,
              party_id: user.party_id,
              party: user.party
            })
          end)

          [user | state]

        _ ->
          if !user.private do
            rec = Enum.at(uu, 0)

            Memento.transaction!(fn ->
              Memento.Query.write(%RoomStatus{
                id: rec.id,
                room_id: user.room_id,
                user_id: user.user_id,
                nickname: user.nickname,
                private: user.private,
                party_id: user.party_id,
                party: user.party
              })
            end)

            state
          end
      end

    {:noreply, state}
  end

  # =============================================================
  # def handle_cast({:user_logout, user_id}, state) do
  # =============================================================
  def handle_cast({:user_logout, user_id}, state) do
    all_rooms = Repo.all(Room)

    Enum.each(all_rooms, fn room ->
      Presence.untrack(self(), topic(room.id), user_id)
    end)

    q = [
      {:==, :user_id, user_id}
    ]

    uu =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, q)
      end)

    Enum.each(uu, fn u ->
      Memento.transaction!(fn ->
        Memento.Query.delete(RoomStatus, u.id)
      end)
    end)

    q = [
      {:==, :party_id, user_id}
    ]

    uu =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, q)
      end)

    Enum.each(uu, fn u ->
      Memento.transaction!(fn ->
        Memento.Query.delete(RoomStatus, u.id)
      end)
    end)

    Phoenix.PubSub.broadcast(Chatlag.PubSub, @lo_topic, {:user_logedout, user_id})

    {:noreply, state}
  end

  defp user_exists(user) do
    # Memento.start()
    guards =
      case user.private do
        true ->
          [
            {:==, :room_id, user.room_id},
            {:==, :user_id, user.user_id},
            {:==, :party_id, user.party_id},
            {:==, :private, user.private}
          ]

        _ ->
          [
            {:==, :user_id, user.user_id},
            ## not private
            {:!=, :private, true}
          ]
      end

    Memento.transaction!(fn ->
      Memento.Query.select(RoomStatus, guards)
    end)
  end

  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end
end
