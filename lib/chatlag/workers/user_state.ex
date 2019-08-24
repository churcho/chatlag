defmodule Chatlag.Workers.UserState do
  use GenServer

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

  # CALLBACKS
  def init(state) do
    {:ok, state}
  end

  def handle_call({:all_rooms, _user}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:add_user, user}, state) do
    r = Enum.find(state, nil, fn u -> user == u end)

    case r do
      nil ->
        {:noreply, [user | state]}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:del_user, user}, state) do
    n = Enum.find_index(state, fn u -> u == user end)

    case n do
      nil -> {:noreplay, state}
      _ -> {:noreplay, Enum.drop(state, n)}
    end
  end
end
