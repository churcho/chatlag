defmodule Chatlag.Repo.Migrations.AddMediaToMessage do
  use Ecto.Migration

  def change do
    alter table("messagese") do
      add :media_type, :string
      add :media, :string
    end
  end
end
