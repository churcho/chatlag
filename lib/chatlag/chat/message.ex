defmodule Chatlag.Chat.Message do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset

  schema "messagese" do
    field :content, :string
    field :reply_to, :integer
    field :user_id, :id
    field :room_id, :id
    field :media, ChatlagWeb.DisplayMedia.Type
    field :media_type, :string

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :reply_to, :user_id, :room_id, :media_type])
    |> cast_attachments(attrs, [:media])
    |> validate_required([:user_id, :room_id])
  end
end
