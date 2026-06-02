defmodule Accountkit.Repo.Migrations.AddDashboardFieldsToEndUsers do
  use Ecto.Migration

  def change do
    alter table(:end_users) do
      add :phone, :text
      add :banned_at, :utc_datetime_usec
      add :auth_methods, {:array, :text}, null: false, default: ["password"]
    end

    create index(:end_users, [:banned_at])
    create index(:end_users, [:archived_at])
  end
end
