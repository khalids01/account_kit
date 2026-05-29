defmodule AccountkitWeb.Features.Organizations.Queries do
  alias Accountkit.Accounts.{Organization, OrganizationMembership}

  def dashboard_data(user) do
    %{
      organizations: organizations_for_platform(user),
      org_admin_memberships: org_admin_memberships_for_platform(user)
    }
  end

  def organizations_for_platform(user) do
    Organization
    |> Ash.Query.for_read(:list_for_platform, %{}, actor: user)
    |> Ash.Query.load([:end_users_count, memberships: :user])
    |> Ash.read!()
  end

  def org_admin_memberships_for_platform(user) do
    OrganizationMembership
    |> Ash.Query.for_read(:list_org_admins_for_platform, %{}, actor: user)
    |> Ash.Query.load([:user, :organization])
    |> Ash.read!()
  end
end
