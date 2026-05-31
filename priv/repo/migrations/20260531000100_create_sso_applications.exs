defmodule Accountkit.Repo.Migrations.CreateSsoApplications do
  use Ecto.Migration

  def change do
    create table(:sso_applications, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text, null: false
      add :logo_url, :text
      add :allowed_origins, {:array, :text}, null: false, default: []
      add :redirect_urls, {:array, :text}, null: false, default: []
      add :email_from_name, :text
      add :email_from_address, :text
      add :password_enabled, :boolean, null: false, default: true
      add :magic_link_enabled, :boolean, null: false, default: true
      add :google_enabled, :boolean, null: false, default: false
      add :google_client_id, :text
      add :encrypted_google_client_secret, :binary
      add :facebook_enabled, :boolean, null: false, default: false
      add :facebook_app_id, :text
      add :encrypted_facebook_app_secret, :binary
      add :linkedin_enabled, :boolean, null: false, default: false
      add :linkedin_client_id, :text
      add :encrypted_linkedin_client_secret, :binary
      add :encrypted_client_token, :binary, null: false
      add :client_token_hash, :binary, null: false

      add :organization_id,
          references(:organizations,
            column: :id,
            name: "sso_applications_organization_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      timestamps(inserted_at: :created_at, type: :utc_datetime_usec)
    end

    create index(:sso_applications, [:organization_id])

    create unique_index(:sso_applications, [:client_token_hash],
             name: "sso_applications_unique_client_token_hash_index"
           )
  end
end
