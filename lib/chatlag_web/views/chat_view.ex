defmodule ChatlagWeb.ChatView do
  use ChatlagWeb, :view
  use Timex

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

  # https://wa.me/?text=Chatlaghttp%3A%2F%2Fwww.efrat37.co.il%2F%23%2Fchat%3Froom%3D%25D7%25A4%25D7%2595%25D7%259C%25D7%2599%25D7%2598%25D7%2599%25D7%25A7%25D7%2594
  # https://twitter.com/intent/tweet?text=Chatlag%20http%3A%2F%2Fwww.efrat37.co.il%2F%23%2Fchat%3Froom%3D%25D7%25A4%25D7%2595%25D7%259C%25D7%2599%25D7%2598%25D7%2599%25D7%25A7%25D7%2594
  # https://facebook.com/sharer.php?u=http%3A%2F%2Fwww.efrat37.co.il%2F%23%2Fchat%3Froom%3D%25D7%25A4%25D7%2595%25D7%259C%25D7%2599%25D7%2598%25D7%2599%25D7%25A7%25D7%2594
  def shareMessage(url, media, msg) do
    thisUrl = "https://chatlag.co.il#{url}"

    link =
      case media do
        :facebook ->
          "https://facebook.com/sharer.php?u=#{thisUrl}&message=#{msg}"

        :wp ->
          "https://wa.me/?text=#{thisUrl} #{msg}"

        :twitter ->
          "https://twitter.com/intent/tweet?text=#{thisUrl} #{msg}"
      end

    "#{link}"
  end

  def meClass(me, id) do
    if me == id, do: 1, else: 2
  end

  def showDate(dt) do
    timezone = Timezone.get("Asia/Jerusalem", Timex.now())
    {:ok, dt} = Timezone.convert(dt, timezone) |> Timex.format("%H:%M", :strftime)
    dt
  end

  def private_room(u1, u2) do
    room_title = "room_#{u2}_#{u1}"

    room = Room |> where(title: ^room_title) |> Repo.one()

    room =
      case room do
        nil ->
          room_title = "room_#{u1}_#{u2}"
          Room |> where(title: ^room_title) |> Repo.one()

        _ ->
          room
      end

    room =
      case room do
        nil ->
          {:ok, room} =
            Chat.create_room(%{
              title: room_title,
              attached: gettext("Private Room"),
              is_private: true
            })

          room

        _ ->
          room
      end

    room.id
  end
end
