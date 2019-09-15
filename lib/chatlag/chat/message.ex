defmodule Chatlag.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messagese" do
    field :user_id, :id
    field :room_id, :id
    field :content, :string
    field :reply_to, :integer
    field :media, :string
    field :media_type, :string
    field :new_media, :string, virtual: true
    field :media_name, :string, virtual: true
    field :media_content, :string, virtual: true
    field :media_size, :integer, virtual: true

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :content,
      :reply_to,
      :user_id,
      :room_id,
      :media_type,
      :media_content,
      :media,
      :media_name,
      :new_media,
      :media_size
    ])
    # |> save_image([:media_content])
    |> validate_required([:user_id, :room_id])

    # added validations
    # doesn't allow empty files
    # |> validate_number(:media_size, greater_than: 0)

    # |> validate_length(:hash, is: 64)
  end

  defp save_image(changeset, field, options \\ []) do
    IO.inspect(field, label: "Before save")
    []
  end
end
