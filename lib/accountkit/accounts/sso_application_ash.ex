defmodule Accountkit.Accounts.SsoApplication do
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshCloak]

  postgres do
    table "sso_applications"
    repo Accountkit.Repo
  end

  cloak do
    vault(Accountkit.Vault)

    attributes([
      :client_token,
      :google_client_secret,
      :facebook_app_secret,
      :linkedin_client_secret
    ])
  end

  actions do
    defaults [:read, :destroy]

    read :list_for_platform do
      description "List all SSO applications for the platform control plane"

      prepare build(sort: [name: :asc])
    end

    read :list_for_organization do
      argument :organization_id, :uuid, allow_nil?: false

      filter expr(organization_id == ^arg(:organization_id))
      prepare build(sort: [name: :asc])
    end

    read :get_by_client_token_hash do
      get? true

      argument :client_token_hash, :binary, allow_nil?: false

      filter expr(client_token_hash == ^arg(:client_token_hash))
    end

    create :create do
      primary? true

      accept [
        :organization_id,
        :name,
        :logo_url,
        :allowed_origins,
        :redirect_urls,
        :email_from_name,
        :email_from_address,
        :password_enabled,
        :magic_link_enabled,
        :google_enabled,
        :google_client_id,
        :google_client_secret,
        :facebook_enabled,
        :facebook_app_id,
        :facebook_app_secret,
        :linkedin_enabled,
        :linkedin_client_id,
        :linkedin_client_secret
      ]

      change &generate_client_token/2
    end

    update :update do
      primary? true
      require_atomic? false

      accept [
        :name,
        :logo_url,
        :allowed_origins,
        :redirect_urls,
        :email_from_name,
        :email_from_address,
        :password_enabled,
        :magic_link_enabled,
        :google_enabled,
        :google_client_id,
        :google_client_secret,
        :facebook_enabled,
        :facebook_app_id,
        :facebook_app_secret,
        :linkedin_enabled,
        :linkedin_client_id,
        :linkedin_client_secret
      ]
    end

    update :rotate_token do
      require_atomic? false
      accept []

      change &generate_client_token/2
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner

      authorize_if expr(
                     exists(
                       organization.memberships,
                       user_id == ^actor(:id) and role == :org_admin
                     )
                   )
    end

    policy action(:create) do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
      authorize_if Accountkit.Accounts.Checks.ApplicationOrgAdmin
    end

    policy action_type([:update, :destroy]) do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner

      authorize_if expr(
                     exists(
                       organization.memberships,
                       user_id == ^actor(:id) and role == :org_admin
                     )
                   )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints trim?: true, allow_empty?: false
    end

    attribute :logo_url, :string do
      public? true
      constraints trim?: true
    end

    attribute :allowed_origins, {:array, :string} do
      allow_nil? false
      default []
      public? true
    end

    attribute :redirect_urls, {:array, :string} do
      allow_nil? false
      default []
      public? true
    end

    attribute :email_from_name, :string do
      public? true
      constraints trim?: true
    end

    attribute :email_from_address, :string do
      public? true
      constraints trim?: true
    end

    attribute :password_enabled, :boolean do
      allow_nil? false
      default true
      public? true
    end

    attribute :magic_link_enabled, :boolean do
      allow_nil? false
      default true
      public? true
    end

    attribute :google_enabled, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :google_client_id, :string do
      public? true
      constraints trim?: true
    end

    attribute :google_client_secret, :string do
      sensitive? true
    end

    attribute :facebook_enabled, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :facebook_app_id, :string do
      public? true
      constraints trim?: true
    end

    attribute :facebook_app_secret, :string do
      sensitive? true
    end

    attribute :linkedin_enabled, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :linkedin_client_id, :string do
      public? true
      constraints trim?: true
    end

    attribute :linkedin_client_secret, :string do
      sensitive? true
    end

    attribute :client_token, :string do
      allow_nil? false
      sensitive? true
    end

    attribute :client_token_hash, :binary do
      allow_nil? false
      sensitive? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organization, Accountkit.Accounts.Organization do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_client_token_hash, [:client_token_hash]
  end

  def generate_client_token(changeset, _context) do
    token = generate_token()

    changeset
    |> AshCloak.encrypt_and_set(:client_token, token)
    |> Ash.Changeset.force_change_attribute(:client_token_hash, hash_token(token))
  end

  def generate_token do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  def hash_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end
end
