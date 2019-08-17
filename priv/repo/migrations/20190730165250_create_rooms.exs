defmodule Chatlag.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :title, :string
      add :slogen, :string
      add :attached, :string
      add :slug, :string
      add :on_front, :boolean, default: false, null: false
      add :small_desc, :text
      add :bg_color, :string
      add :bg_image, :string
      add :bg_small_image, :string
      add :room_icon, :string
      add :min_age, :integer

      timestamps()
    end
  end
end
