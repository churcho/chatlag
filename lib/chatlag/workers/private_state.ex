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
    q = [
      {:==, :party_id, party_id}
    ]

    Memento.transaction!(fn ->
      Memento.Query.select(PrivateStatus, q)
    end)
  end

  def private_count(party_id) do
    privates_list(party_id)
    |> Enum.filter(fn %PrivateStatus{count: c} = _x -> c > 0 end)
    |> Enum.count()
  end

  def add_private(party_id, room_id, user_id) do

    q = [
      {:==, :room_id, room_id},
      {:==, :party_id, party_id},
      {:==, :user_id, user_id}
    ]

    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, q)
      end)

    case res do
      [] ->
        Memento.transaction!(fn ->
          Memento.Query.write(%PrivateStatus{
            room_id: room_id,
            party_id: party_id,
            user_id: user_id,
            count: 1
          })
        end)

      _ ->
        for r <- res do
          Memento.transaction!(fn ->
            r = Map.put(r, :count, 1)
            Memento.Query.write(r)
          end)
        end
    end
  end

  def sub_private(party_id, room_id, user_id) do

    q = [
      {:==, :room_id, room_id},
      {:==, :party_id, user_id},
      {:==, :user_id, party_id}
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
            r = Map.put(r, :count, 0)
            Memento.Query.write(r)
          end)
        end
    end
  end

  def is_blocked(party_id, user_id) do
    q = [
      {:==, :party_id, party_id},
      {:==, :user_id, user_id},
      {:==, :blocked, 1}
    ]

    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, q)
      end)

    case res do
      [] ->
        q = [
          {:==, :party_id, user_id},
          {:==, :user_id, party_id},
          {:==, :blocked, 1}
        ]

        res =
          Memento.transaction!(fn ->
            Memento.Query.select(PrivateStatus, q)
          end)

        case res do
          [] -> false
          _ -> true
        end

      _ ->
        true
    end
  end
end
