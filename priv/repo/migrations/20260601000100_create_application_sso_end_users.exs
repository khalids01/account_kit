defmodule Accountkit.Repo.Migrations.CreateApplicationSsoEndUsers do
  use Ecto.Migration

  def change do
    create table(:end_users, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text, null: false
      add :email, :citext, null: false
      add :login_id, :citext, null: false
      add :hashed_password, :text
      add :confirmed_at, :utc_datetime_usec
      add :archived_at, :utc_datetime_usec

      add :sso_application_id,
          references(:sso_applications,
            column: :id,
            name: "end_users_sso_application_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false

      timestamps(inserted_at: :created_at, type: :utc_datetime_usec)
    end

    create index(:end_users, [:sso_application_id])

    create unique_index(:end_users, [:login_id], name: "end_users_unique_login_id_index")

    create unique_index(:end_users, [:sso_application_id, :email],
             name: "end_users_unique_email_per_application_index"
           )

    create table(:end_user_tokens, primary_key: false) do
      add :jti, :text, null: false, primary_key: true
      add :subject, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :purpose, :text, null: false
      add :extra_data, :map

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end
  end
end
