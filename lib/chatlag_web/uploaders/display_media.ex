defmodule ChatlagWeb.DisplayMedia do
  use Arc.Definition
  use Arc.Ecto.Definition

  def __storage, do: Arc.Storage.Local

  @acl :public_read
  @versions [:primary]

  def storage_dir(:primary, {_file, message}) do
    room_id = message.room_id
    "uploads/message/#{room_id}"
  end

  def default_url(:primary, _message) do
    ""
  end
end
