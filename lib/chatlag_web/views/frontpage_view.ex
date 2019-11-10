defmodule ChatlagWeb.FrontpageView do
  use ChatlagWeb, :view

  alias Chatlag.Chat
  alias ChatlagWeb.DisplayIcon

  def getRoomIcon(id) do
    room = Chat.get_room!(id)

    {room.room_icon, room}
    |> DisplayIcon.url()
  end

  def shareMessage(media) do
    thisUrl = "https://chat.chatlag.co.il"

    link =
      case media do
        :facebook ->
          "https://facebook.com/sharer.php?u=#{thisUrl}"

        :wp ->
          "https://api.whatsapp.com/send?text=רציתי לשתף אתכם באתר הזה #{thisUrl}&url=https://chat.chatlag.co.il"

        :twitter ->
          "https://twitter.com/intent/tweet?text=#{thisUrl}"
      end

    "#{link}"
  end
end
