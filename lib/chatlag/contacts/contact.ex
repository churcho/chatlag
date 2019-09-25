defmodule Chatlag.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :completed, :boolean, default: false
    field :email, :string
    field :message, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :email, :message, :completed])
    |> validate_required([:name, :email, :message, :completed])
  end
end
