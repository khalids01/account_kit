defmodule Accountkit.Accounts.OrganizationMembership do
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organization_memberships"
    repo Accountkit.Repo
    identity_index_names unique_organization_user_membership: "organization_memberships_org_user_index"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:organization_id, :user_id, :role]
    end

    read :get_by_user_org_and_role do
      get? true

      argument :user_id, :uuid do
        allow_nil? false
      end

      argument :organization_id, :uuid do
        allow_nil? false
      end

      argument :role, :atom do
        allow_nil? false
        constraints one_of: [:org_admin]
      end

      filter expr(
               user_id == ^arg(:user_id) and organization_id == ^arg(:organization_id) and
                 role == ^arg(:role)
             )
    end

    read :for_user do
      argument :user_id, :uuid do
        allow_nil? false
      end

      filter expr(user_id == ^arg(:user_id))
    end

    read :for_organization do
      argument :organization_id, :uuid do
        allow_nil? false
      end

      filter expr(organization_id == ^arg(:organization_id))
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
    end

    policy action(:create) do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
      authorize_if Accountkit.Accounts.Checks.CreatingFirstOwnOrgAdminMembership
    end

    policy action(:destroy) do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:org_admin]
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organization, Accountkit.Accounts.Organization do
      allow_nil? false
    end

    belongs_to :user, Accountkit.Accounts.User do
      allow_nil? false
    end
  end

  identities do
    identity :unique_organization_user_membership, [:organization_id, :user_id]
  end
end
