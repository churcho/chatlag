defmodule Chatlag.Workers.UserState do
  use GenServer

  # API
  def start_link(_state) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_user(user) do
    GenServer.cast(__MODULE__, {:add_user, user})
  end

  # CALLBACKS
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_user, user}, state) do
    {:noreply, [user | state]}
  end
end
