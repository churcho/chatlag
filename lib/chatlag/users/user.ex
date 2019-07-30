defmodule Chatlag.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :age, :integer, null: false
    field :full_name, :string, null: true
    field :email, :string, null: true
    field :password_hash, :string, null: true
    field :password, :string, null: true, virtual: true
    field :gender, :string, null: false
    field :ip_address, :string, null: true
    field :role, :string, null: false
    field :nickname, :string, null: false
    field :suspend_at, :date, null: true

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:nickname, :full_name, :email, :role, :age, :gender, :ip_address, :suspend_at, :password_hash])
    |> validate_required([:nickname, :age, :gender])
  end
end
