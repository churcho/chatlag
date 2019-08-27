defmodule Chatlag.Workers.UserState do
  use GenServer

  alias Chatlag.RoomStatus

  # API
  def start_link(_state) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_user(user) do
    GenServer.cast(__MODULE__, {:add_user, user})
  end

  def del_user(user) do
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
    IO.puts("Worker started")

    {:ok, state}
  end

  def handle_call({:close_private_room, room_id}, _from, state) do
    room_id = String.to_integer(room_id)
    IO.inspect(room_id, label: "Close room")
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
        IO.puts("delete room #{r.id}")
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
    # IO.puts("I am #{user_id}")
    # IO.inspect(all, label: "My private chat *************************")

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

  def handle_cast({:del_user, user}, state) do
    n = Enum.find_index(state, fn u -> u == user end)

    case n do
      nil -> {:noreplay, state}
      _ -> {:noreplay, Enum.drop(state, n)}
    end
  end

  defp user_exists(user) do
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
            {:!=, :private, true}
          ]
      end

    Memento.transaction!(fn ->
      Memento.Query.select(RoomStatus, guards)
    end)
  end
end
