defmodule Chatlag.PrivateMsg do
  alias Chatlag.PrivateStatus

  def reset do
    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, [])
      end)

    for r <- res do
      Memento.transaction!(fn ->
        Memento.Query.delete(PrivateStatus, r.id)
      end)
    end

    :ok
  end

  def all_privates() do
    Memento.transaction!(fn ->
      Memento.Query.select(PrivateStatus, [])
    end)
  end

  def privates_list(party_id) do
    IO.puts("Prv count for : #{party_id}")

    q = [
      {:==, :party_id, party_id}
    ]

    Memento.transaction!(fn ->
      Memento.Query.select(PrivateStatus, q)
    end)
  end

  def private_count(party_id) do
    cnt =
      privates_list(party_id)
      |> Enum.count()

    IO.puts("Find: #{party_id} #{cnt}")

    cnt
  end

  def add_private(party_id, room_id, user_id) do
    IO.inspect("Add: #{party_id} #{room_id} #{user_id}")

    q = [
      {:==, :room_id, room_id},
      {:==, :party_id, party_id},
      {:==, :user_id, user_id}
    ]

    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, q)
      end)

    IO.inspect(res, label: "** find: ")

    case res do
      [] ->
        Memento.transaction!(fn ->
          Memento.Query.write(%PrivateStatus{
            room_id: room_id,
            party_id: party_id,
            user_id: user_id
          })
        end)

      _ ->
        res
    end
  end

  def sub_private(party_id, room_id, user_id) do
    IO.inspect("++++ Sub: [#{party_id}] [#{room_id}] [#{user_id}]")
    q = [
      {:==, :room_id, room_id},
      {:==, :party_id, user_id}
    ]

    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, q)
      end)

    case res do
      [] ->
        res

      _ ->
        for r <- res do
          Memento.transaction!(fn ->
            Memento.Query.delete(PrivateStatus, r.id)
          end)
        end
    end
  end
end
