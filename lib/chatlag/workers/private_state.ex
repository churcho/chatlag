defmodule Chatlag.PrivateMsg do
  alias Chatlag.PrivateStatus

  def reset do
    :ok
  end

  def add_private(uid, rid, nickname) do
    q = [
      {:==, :room_id, rid},
      {:==, :party_id, uid}
    ]

    res =
      Memento.transaction!(fn ->
        Memento.Query.select(PrivateStatus, q)
      end)

    case res do
      [] ->
        Memento.transaction!(fn ->
          Memento.Query.write(%PrivateStatus{
            room_id: rid,
            party_id: uid,
            nickname: nickname
          })
        end)

      _ ->
        res
    end
  end

  def privates(uid) do
    q = [
      {:==, :party_id, uid}
    ]

    Memento.transaction!(fn ->
      Memento.Query.select(PrivateStatus, q)
    end)
  end

  def private_count(uid) do
    privates(uid)
    |> Enum.count()
  end

  def sub_private(uid, rid) do
    q = [
      {:==, :room_id, rid},
      {:==, :party_id, uid}
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
            IO.puts("Delete #{r.id}")
            Memento.Query.delete(PrivateStatus, r.id)
          end)
        end
    end
  end
end
