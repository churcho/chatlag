defmodule ChatlagWeb.ChatView do
  use ChatlagWeb, :view
  use Timex

  import Ecto.Query, warn: true

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
  def shareMessage(url, media, msg \\ "") do
    thisUrl = "https://chatlag.co.il#{url}"
    # https://api.whatsapp.com/send?text=%22kjkj%20kj%20kjk%22&url=lll.com
    link =
      case media do
        :facebook ->
          "https://facebook.com/sharer.php?u=#{thisUrl}&message=#{msg}"

        :wp ->
          "https://api.whatsapp.com/send?text=#{thisUrl}  #{msg} "

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

    if room.url do
      "<a href='#{room.url}' target='_blank'>#{room.attached}</a>"
    else
      room.attached
    end
  end

  def msg_content(msg_id) do
    resWords = Chatlag.Reserved.get_first_content()

    tr = fn s1 ->
      resWords |> Enum.reduce(s1, fn x, acc -> String.replace(String.trim(acc), x, "***") end)
    end

    if msg_id do
      msg = Chat.get_message!(msg_id)

      case msg do
        nil ->
          nil

        _ ->
          case msg.content do
            nil ->
              nil

            "" ->
              nil

            _ ->
              content =
                msg.content
                |> String.split(" ")
                |> Enum.filter(fn w -> String.length(w) < 18 end)
                |> Enum.join(" ")

              tr.(content) |> String.replace(~r/(\*\*\*)+/, "***")
          end
      end
    else
      nil
    end
  end

  def msg_nickname(msg_id) do
    msg = Chat.get_message!(msg_id)

    # nick =
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

  def is_blocked(user_id, party_id) do
    Chatlag.PrivateMsg.is_blocked(user_id, party_id)
  end

  defp get_msg_by_reply(reply_to) do
    Message |> where(reply_to: ^reply_to) |> Repo.all()
  end

  def msg_by_reply(id) do
    get_msg_by_reply(id)
  end

  def is_admin(user_id) do
    user = Users.get_user!(user_id, true)
    user.role == "admin"
  end

  def get_admin do
    admin =
      for u <- Users.online_users() do
        user = Users.get_user!(u.user_id, true)

        if user.role == "admin" do
          user.id
        end
      end

    if admin do
      admin |> Enum.filter(& &1) |> List.first()
    else
      nil
    end
  end

  def revealSection(display, section) do
    if display == section do
      ""
    else
      "hidden"
    end
  end

  def admin_class(user_id) do
    user = Users.get_user!(user_id, true)

    if user.role == "admin" do
      "is-admin"
    else
      ""
    end
  end

  def user_suspended(user_id) do
    user = Users.get_user!(user_id, true)
    user.suspend_at != nil
  end

  def user_suspended(user_id, party_id) do
    user = Users.get_user!(user_id, true)

    if user.role == "admin" do
      false
    else
      party =
        case party_id do
          nil ->
            party_id

          _ ->
            p = Users.get_user!(party_id, true)
            p
        end

      if user.suspend_at != nil do
        if party_id && party.role == "admin" do
          false
        else
          true
        end
      else
        false
      end
    end
  end
end
