defmodule ChatlagWeb.DisplayImage do
  use Arc.Definition
  use Arc.Ecto.Definition

  def __storage, do: Arc.Storage.Local

  @acl :public_read
  @versions [:primary]

  def storage_dir(:primary, {file, room}) do
    slug = room.slug
    "uploads/rooms/bg/#{slug}"
  end

  def default_url(:primary, _room) do
    ""
  end
end
