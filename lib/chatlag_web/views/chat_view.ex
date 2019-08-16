defmodule ChatlagWeb.ChatView do
  use ChatlagWeb, :view
  import Ecto.Query

  alias ChatlagWeb.DisplayImage
  alias ChatlagWeb.DisplayIcon

  alias Chatlag.Accounts

  alias Chatlag.Chat

  alias Chatlag.Repo

  alias Chatlag.Chat.Room

  def getRoomBg(id) do
    room = Chat.get_room!(id)

    {room.bg_image, room}
    |> DisplayImage.url()
  end

  def getRoomMidsizeBg(id) do
    room = Chat.get_room!(id)

    {room.midsize_image, room}
    |> DisplayImage.url()
  end

  def getRoomSmallBg(id) do
    room = Chat.get_room!(id)

    {room.bg_small_image, room}
    |> DisplayImage.url()
  end

  def getRoomIcon(id) do
    room = Chat.get_room!(id)

    {room.room_icon, room}
    |> DisplayIcon.url()
  end

  def getUserIcon(uid) do
    user = Accounts.get_user!(uid)

    if user.gender == "F" do
      "/images/female.png"
    else
      "/images/male.png"
    end
  end

  def getUserNickname(uid) do
    user = Accounts.get_user!(uid)
    user.nickname
  end

  def getNext(id) do
    q =
      from(r in Room,
        select: %{id: r.id, title: r.title, slogen: r.slogen},
        where: r.on_front == false,
        where: r.id > ^id,
        order_by: r.id,
        limit: 2
      )

    {Repo.all(q), 78}
  end
end
