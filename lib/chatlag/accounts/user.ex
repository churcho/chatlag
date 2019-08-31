defmodule Chatlag.Accounts.User do
  use Ecto.Schema

  alias ChatlagWeb.Presence
  import Ecto.Changeset

  use Pow.Ecto.Schema,
    password_min_length: 5

  schema "users" do
    pow_user_fields()
    field :age, :integer, null: false
    field :full_name, :string, null: true
    field :gender, :string, null: false
    field :ip_address, :string, null: true
    field :role, :string, null: false
    field :is_loggedin, :boolean, default: false
    field :nickname, :string, null: false
    field :suspend_at, :date, null: true

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :nickname,
      :full_name,
      :email,
      :role,
      :age,
      :gender,
      :ip_address,
      :is_loggedin,
      :suspend_at,
      :password_hash
    ])
    |> validate_required([:nickname, :age, :gender])
    |> pow_changeset(attrs)
    |> validate_length(:nickname, max: 18)
    |> validate_online(:nickname)
    |> unique_constraint(:email) 
  end

  def validate_online(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, nickname ->
      case user_exists(nickname) do
        false -> []
        true -> [{field, options[:message] || "Nickname already taken"}]
      end
    end)
  end

  defp user_exists(user) do
    users = Presence.list("chatlag")

    usr = users |> Map.get(user)

    case usr do
      nil ->
        false

      _ ->
        true
    end
  end
end
