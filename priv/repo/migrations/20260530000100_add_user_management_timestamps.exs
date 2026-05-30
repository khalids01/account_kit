defmodule Accountkit.Repo.Migrations.AddUserManagementTimestamps do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :banned_at, :utc_datetime_usec
      add :archived_at, :utc_datetime_usec
    end
  end
end
