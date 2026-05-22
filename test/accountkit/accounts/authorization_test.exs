defmodule Accountkit.Accounts.AuthorizationTest do
  use Accountkit.DataCase

  alias Accountkit.Accounts.{
    Authorization,
    Organization,
    OrganizationMembership,
    PlatformRole,
    User
  }

  test "platform_owner?/1 is true only for users with a platform owner role" do
    owner = user!("owner@example.com")
    regular_user = user!("user@example.com")

    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    assert Authorization.platform_owner?(owner)
    refute Authorization.platform_owner?(regular_user)
    refute Authorization.platform_owner?(nil)
  end

  test "org_admin?/2 is scoped to the organization" do
    user = user!("admin@example.com")
    organization = organization!("Acme")
    other_organization = organization!("Other")

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: user.id,
      role: :org_admin
    })

    assert Authorization.org_admin?(user, organization.id)
    refute Authorization.org_admin?(user, other_organization.id)
  end

  test "dashboard_user?/1 allows platform owners and org admins but denies unrelated users" do
    platform_owner = user!("platform@example.com")
    org_admin = user!("org-admin@example.com")
    regular_user = user!("regular@example.com")
    organization = organization!("Dashboard Org")

    Ash.Seed.seed!(PlatformRole, %{user_id: platform_owner.id, role: :platform_owner})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: org_admin.id,
      role: :org_admin
    })

    assert Authorization.dashboard_user?(platform_owner)
    assert Authorization.dashboard_user?(org_admin)
    refute Authorization.dashboard_user?(regular_user)
  end

  defp user!(email) do
    Ash.Seed.seed!(User, %{email: email, name: "Test User"})
  end

  defp organization!(name) do
    Ash.Seed.seed!(Organization, %{name: name})
  end
end
