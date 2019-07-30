defmodule Chatlag.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :title, :string
      add :slug, :string
      add :on_front, :boolean, default: false, null: false
      add :small_desc, :text
      add :min_age, :integer

      timestamps()
    end

  end
end
