defmodule Chatlag.Workers.Cache do
  use GenServer

  @users_table :users_cache
  @rooms_table :rooms_cache
  # API
  def start_link(_state) do
    GenServer.start_link(__MODULE__, %{}, name: ChatlagCache)
  end

  def delete_user(key) do
    GenServer.cast(ChatlagCache, {:delete_user, key})
  end

  def get_user(key) do
    GenServer.call(ChatlagCache, {:get_user, key})
  end

  def put_user(key, data) do
    GenServer.cast(ChatlagCache, {:put_user, key, data})
  end

  ################ Rooms ###########################
  def delete_room(key) do
    GenServer.cast(ChatlagCache, {:delete_room, key})
  end

  def get_room(key) do
    GenServer.call(ChatlagCache, {:get_room, key})
  end

  def put_room(key, data) do
    GenServer.cast(ChatlagCache, {:put_room, key, data})
  end

  # CALLBACKS
  def init(state) do
    IO.puts("Cache started")
    :ets.new(@users_table, [:set, :public, :named_table])
    :ets.new(@rooms_table, [:set, :public, :named_table])
    {:ok, state}
  end

  def handle_cast({:delete_user, key}, state) do
    :ets.delete(@users_table, key)
    {:noreply, state}
  end

  def handle_cast({:put_user, key, data}, state) do
    :ets.insert(@users_table, {key, data})
    {:noreply, state}
  end

  def handle_call({:get_user, key}, _from, state) do
    reply =
      case :ets.lookup(@users_table, key) do
        [] ->
          nil

        [{_key, user}] ->
          user
      end

    {:reply, reply, state}
  end

  ########## Rooms
  def handle_cast({:delete_room, key}, state) do
    :ets.delete(@rooms_table, key)
    {:noreply, state}
  end

  def handle_cast({:put_room, key, data}, state) do
    :ets.insert(@rooms_table, {key, data})
    {:noreply, state}
  end

  def handle_call({:get_room, key}, _from, state) do
    reply =
      case :ets.lookup(@rooms_table, key) do
        [] ->
          nil

        [{_key, room}] ->
          room
      end

    {:reply, reply, state}
  end
end
