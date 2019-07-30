defmodule Chatlag.Chat.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :min_age, :integer
    field :on_front, :boolean, default: false
    field :slug, :string
    field :small_desc, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:title, :slug, :on_front, :small_desc, :min_age])
    |> validate_required([:title, :slug, :on_front, :small_desc, :min_age])
  end
end
