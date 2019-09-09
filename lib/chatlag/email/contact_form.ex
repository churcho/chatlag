defmodule Chatlag.Emails.ContactForm do
  import Ecto.Changeset
  alias Chatlag.{Mailer, Emails}

  defstruct [:email, :message, :name]

  @types %{
    name: :string,
    email: :string,
    message: :string
  }

  def changeset(attrs \\ %{}) do
    {%__MODULE__{}, @types}
    |> cast(attrs, [:email, :message, :name])
    |> validate_required([:email, :message, :name])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:name, min: 2)
    |> validate_length(:message, min: 5)
  end

  def send(changeset) do
    case changeset.valid? do
      true ->
        IO.inspect(changeset, label: "sending mail***")

        changeset.changes
        |> Emails.contact_email()
        |> Mailer.deliver_now()

        {:ok, changeset}

      false ->
        {:error, changeset}
    end
  end
end
