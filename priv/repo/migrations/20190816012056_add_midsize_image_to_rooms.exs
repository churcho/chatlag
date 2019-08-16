defmodule Chatlag.Repo.Migrations.AddMidsizeImageToRooms do
  use Ecto.Migration

  def change do
    alter table("rooms") do
      add :midsize_image, :string
    end
  end
end
