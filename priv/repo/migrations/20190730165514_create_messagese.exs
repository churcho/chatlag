defmodule Chatlag.Repo.Migrations.CreateMessagese do
  use Ecto.Migration

  def change do
    create table(:messagese) do
      add :content, :text
      add :reply_to, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps()
    end

    create index(:messagese, [:user_id])
    create index(:messagese, [:room_id])
  end
end
