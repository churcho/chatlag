defmodule Chatlag.Repo.Migrations.AddUniqueToUsers do
  use Ecto.Migration

  def change do
    # alter table("users") do
      create unique_index(:users, [:email])
    # end
  end
end
