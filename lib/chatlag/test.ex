defmodule Chatlag.Test do
  import Ecto.Query

  alias Chatlag.Repo

  alias Chatlag.Chat.Room
  # alias Chatlag.Chat

  def test(id) do
    rr =
      Repo.all(
        from(r in Room,
          select: %{id: r.id, title: r.title, slogen: r.slogen},
          where: r.on_front == false,
          order_by: r.id
        )
      )

    xx = Enum.chunk_every(rr, 2)

    for [aa,bb] <- xx do
      aa
    end
  end
end
