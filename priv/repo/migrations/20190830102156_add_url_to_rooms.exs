defmodule Chatlag.Repo.Migrations.AddUrlToRooms do
  use Ecto.Migration

  def change do
    alter table("rooms") do
      add :url, :string
    end
  end
end
