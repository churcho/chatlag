defmodule Chatlag.PrivateMsg do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add(user) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, user, 1)
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn _state -> %{} end)
  end

  def private_count(user) do
    user = "#{user}"

    count =
      Agent.get(__MODULE__, fn state ->
        Map.get(state, user)
      end)

    case count do
      nil ->
        0

      _ ->
        count
    end
  end

  def add_private(user) do
    # IO.puts("*********** Adding to #{user}")
    user = "#{user}"

    case private_count(user) do
      0 ->
        add(user)

      _ ->
        Agent.update(__MODULE__, fn state ->
          count = Map.get(state, user)
          Map.put(state, user, count + 1)
        end)
    end
  end

  def sub_private(user) do
    # IO.puts("*********** Sbtract from #{user}")
    user = "#{user}"
    if !private_count(user), do: add(user)

    case private_count(user) do
      0 ->
        :ok

      _ ->
        Agent.update(__MODULE__, fn state ->
          count = Map.get(state, user)
          Map.put(state, user, count - 1)
        end)
    end
  end
end
