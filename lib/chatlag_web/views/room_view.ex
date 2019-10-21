defmodule ChatlagWeb.RoomView do
  use ChatlagWeb, :view
  alias ChatlagWeb.DisplayImage
  alias ChatlagWeb.DisplayIcon

  alias Chatlag.Chat
  alias Chatlag.Users

  import Scrivener.HTML

  def getRoomName(rid) do
    room = Chat.get_room!(rid)
    room.title
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

  def getUserNickname(uid) do
    user = Users.get_user!(uid)
    user.nickname
  end

  def getUserIcon(uid) do
    user = Users.get_user!(uid)

    if user.image do
      user.image
    else
      if user.role == "admin" do
        "/images/header-logo.png"
      else
        if user.gender == "F" do
          "/images/female.png"
        else
          "/images/male.png"
        end
      end
    end
  end

  def is_image(mtype) do
    case mtype do
      nil ->
        false

      _ ->
        [_, image, _] = Regex.run(~r/(.*)\/(.*)/, mtype)
        image == "image"
    end
  end

  def is_video(mtype) do
    case mtype do
      nil ->
        false

      _ ->
        [_, video, _] = Regex.run(~r/(.*)\/(.*)/, mtype)
        video == "video"
    end
  end
end
