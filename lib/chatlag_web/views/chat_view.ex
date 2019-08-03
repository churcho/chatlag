defmodule ChatlagWeb.ChatView do
  use ChatlagWeb, :view

  alias ChatlagWeb.DisplayImage

  alias Chatlag.Chat

  def display_image do
    "ljdkljslkdfj"
  end

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
end
