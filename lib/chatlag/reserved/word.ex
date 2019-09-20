defmodule Chatlag.Reserved.Word do
  use Ecto.Schema
  import Ecto.Changeset

  schema "words" do
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
