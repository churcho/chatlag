defmodule Chatlag.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messagese" do
    field :content, :string
    field :reply_to, :integer
    field :user_id, :id
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :reply_to, :user_id, :room_id])
    |> validate_required([:content, :user_id, :room_id])
  end
end
