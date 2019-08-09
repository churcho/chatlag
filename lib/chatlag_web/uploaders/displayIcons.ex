defmodule ChatlagWeb.DisplayIcon do
  use Arc.Definition
  use Arc.Ecto.Definition

  def __storage, do: Arc.Storage.Local

  @acl :public_read
  @versions [:primary]

  def storage_dir(:primary, {_file, room}) do
    slug = room.slug
    "uploads/rooms/icons/#{slug}"
  end

  def default_url(:primary, _room) do
    "http://placehold.it/60x60"
  end
end
