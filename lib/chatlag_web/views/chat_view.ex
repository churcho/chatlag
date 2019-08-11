defmodule ChatlagWeb.ChatView do
  use ChatlagWeb, :view

  alias ChatlagWeb.DisplayImage
  alias ChatlagWeb.DisplayIcon

  alias Chatlag.Accounts

  alias Chatlag.Chat

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
  
end
