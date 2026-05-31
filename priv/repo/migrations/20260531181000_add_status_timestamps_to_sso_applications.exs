defmodule Accountkit.Repo.Migrations.AddStatusTimestampsToSsoApplications do
  use Ecto.Migration

  def change do
    alter table(:sso_applications) do
      add_if_not_exists :archived_at, :utc_datetime_usec
      add_if_not_exists :deactivated_at, :utc_datetime_usec
    end
  end
end
