defmodule Chatlag.Repo.Migrations.AddSuspendCountToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :suspend_counter, :integer, default: 0
    end
  end
end
