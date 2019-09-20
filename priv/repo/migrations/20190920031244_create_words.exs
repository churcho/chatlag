defmodule Chatlag.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :content, :text

      timestamps()
    end

  end
end
