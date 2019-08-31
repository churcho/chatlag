defmodule Chatlag.Repo.Migrations.ExpandPasswordInUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      modify :password_hash, :string, null: true, size: 255
    end
  end
end
