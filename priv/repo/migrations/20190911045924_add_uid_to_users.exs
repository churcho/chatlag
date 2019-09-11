defmodule Chatlag.Repo.Migrations.AddUidToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :uid, :string
      add :image, :string
    end
  end
end
