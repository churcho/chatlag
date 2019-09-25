defmodule Chatlag.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :name, :string
      add :email, :string
      add :message, :text
      add :completed, :boolean, default: false, null: false

      timestamps()
    end

  end
end
