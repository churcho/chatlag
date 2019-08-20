defmodule Chatlag.Repo.Migrations.AddPrivateToRooms do
  use Ecto.Migration

  def change do
    alter table("rooms") do
      add :is_private, :boolean, default: false
    end
  end
end
