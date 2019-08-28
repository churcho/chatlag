defmodule Chatlag.Workers.RoomState do
  use GenServer

  alias Chatlag.RoomStatus

  # API
  def start_link(_state) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # CALLBACKS
  def init(state) do
    IO.puts("Room Worker started")

    {:ok, state}
  end
end
