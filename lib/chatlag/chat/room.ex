defmodule Chatlag.Chat.Room do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :min_age, :integer
    field :on_front, :boolean, default: false
    field :is_private, :boolean, default: false
    field :slug, :string
    field :attached, :string
    field :url, :string
    field :bg_color, :string
    field :small_desc, :string
    field :title, :string
    field :slogen, :string
    field :bg_image, ChatlagWeb.DisplayImage.Type
    field :midsize_image, ChatlagWeb.DisplayImage.Type
    field :bg_small_image, ChatlagWeb.DisplayImage.Type
    field :room_icon, ChatlagWeb.DisplayIcon.Type

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    attrs = Map.merge(attrs, slug_map(attrs))

    room
    |> cast(attrs, [
      :title,
      :slug,
      :on_front,
      :is_private,
      :small_desc,
      :bg_color,
      :min_age,
      :attached,
      :url,
      :slogen
    ])
    |> cast_attachments(attrs, [:bg_image])
    |> cast_attachments(attrs, [:midsize_image])
    |> cast_attachments(attrs, [:bg_small_image])
    |> cast_attachments(attrs, [:room_icon])
    |> validate_required([:title])
  end

  defp slug_map(%{"title" => title, "slug" => old_slug}) do
    if String.length(old_slug) == 0 do
      slug = String.downcase(title) |> Slugger.slugify()
      %{"slug" => slug}
    else
      %{"slug" => old_slug}
    end
  end

  defp slug_map(_params) do
    %{}
  end
end
