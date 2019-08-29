defmodule ChatlagWeb.AuthView do
  use ChatlagWeb, :view

  alias ChatlagWeb.Presence
  alias Chatlag.Chat.Room
  alias Chatlag.Repo

  def getUsers do
    all_rooms = Repo.all(Room)
    Enum.reduce(all_rooms, 0, fn r, acc -> users_in_room(r.id) + acc end)
  end

  defp users_in_room(rid) do
    users =
      Presence.list(topic(rid))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    Enum.count(users)
  end

  defp topic(room_id) do
    "Chatlag-msg:#{room_id}"
  end
end
