defmodule ChatlagWeb.RoomView do
  use ChatlagWeb, :view
  alias ChatlagWeb.DisplayImage
  alias ChatlagWeb.DisplayIcon

  alias Chatlag.Chat

  import Scrivener.HTML

  def getRoomBg(id) do
    room = Chat.get_room!(id)

    {room.bg_image, room}
    |> DisplayImage.url()
  end

  def getRoomSmallBg(id) do
    room = Chat.get_room!(id)

    {room.bg_small_image, room}
    |> DisplayImage.url()
  end

  def getRoomMidsizeBg(id) do
    room = Chat.get_room!(id)

    {room.midsize_image, room}
    |> DisplayImage.url()
  end


  def getRoomIcon(id) do
    room = Chat.get_room!(id)

    {room.room_icon, room}
    |> DisplayIcon.url()
  end
end
