defmodule ChatlagWeb.ChatView do
  use ChatlagWeb, :view
  use Timex

  import Ecto.Query, warn: false

  alias ChatlagWeb.DisplayImage
  alias ChatlagWeb.DisplayIcon

  alias Chatlag.Users

  alias Chatlag.Chat

  alias Chatlag.Repo

  alias Chatlag.Chat.Room
  alias Chatlag.Chat.Message
  alias Chatlag.RoomStatus

  def is_online?(user_id) do
    Users.is_online?(user_id)
  end

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
    user = Users.get_user!(uid)

    if user.gender == "F" do
      "/images/female.png"
    else
      "/images/male.png"
    end
  end

  def getRoomParty(room_id, me) do
    q = [
      {:==, :room_id, room_id},
      {:==, :private, true}
    ]

    a =
      Memento.transaction!(fn ->
        Memento.Query.select(RoomStatus, q)
      end)

    a1 = Enum.at(a, 0)

    case Enum.count(a) do
      0 ->
        ""

      _ ->
        getUserNickname(me, a1.user_id, a1.party_id)
    end
  end

  def getUserNickname(me, uid, pid) do
    u =
      if me == pid do
        uid
      else
        pid
      end

    getUserNickname(u)
  end

  def getUserNickname(uid) do
    user = Users.get_user!(uid)
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

  def bg_color(id) do
    room = Chat.get_room!(id)
    room.bg_color
  end

  def attached(id) do
    room = Chat.get_room!(id)
    room.attached
  end

  def msg_content(msg_id) do
    msg = Chat.get_message!(msg_id)
    msg.content
  end

  def msg_nickname(msg_id) do
    msg = Chat.get_message!(msg_id)

    nick =
      if msg do
        user = Users.get_user!(msg.user_id)

        if user do
          user.nickname
        else
          ""
        end
      else
        ""
      end
  end

  defp get_msg_by_reply(reply_to) do
    Message |> where(reply_to: ^reply_to) |> Repo.all()
  end

  def msg_by_reply(id) do
    get_msg_by_reply(id)
  end
end
