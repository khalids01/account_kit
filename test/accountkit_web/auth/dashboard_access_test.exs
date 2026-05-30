defmodule AccountkitWeb.Auth.DashboardAccessTest do
  use AccountkitWeb.ConnCase

  import AshAuthentication.Plug.Helpers
  import Phoenix.LiveViewTest

  alias Accountkit.Accounts.{Organization, OrganizationMembership, PlatformRole, User}

  test "anonymous users are redirected from control-plane routes", %{conn: conn} do
    conn = get(conn, ~p"/admin/rate-limits")

    assert redirected_to(conn) == ~p"/login"
  end

  test "signed-in users without a scoped role are redirected from control-plane routes", %{
    conn: conn
  } do
    user = user!("plain@example.com")

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)
      |> get(~p"/admin/rate-limits")

    assert redirected_to(conn) == ~p"/onboarding/organization"
  end

  test "signed-in users without a scoped role are redirected from dashboard to onboarding", %{
    conn: conn
  } do
    user = user!("needs-onboarding@example.com")

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)
      |> get(~p"/dashboard")

    assert redirected_to(conn) == ~p"/onboarding/organization"
  end

  test "platform owners can access control-plane routes", %{conn: conn} do
    user = user!("owner@example.com")
    Ash.Seed.seed!(PlatformRole, %{user_id: user.id, role: :platform_owner})

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)
      |> get(~p"/admin/rate-limits")

    assert html_response(conn, 200) =~ "Rate limits"
  end

  test "org admins can access dashboard", %{conn: conn} do
    user = user!("org-admin@example.com")
    organization = Ash.Seed.seed!(Organization, %{name: "Acme", text_logo: "Acme"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: user.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)
      |> get(~p"/dashboard")

    assert html_response(conn, 200) =~ "Acme"
  end

  test "platform owners can access organizations page", %{conn: conn} do
    owner = user!("platform-orgs@example.com")
    org_admin = user!("org-owner@example.com", "Org Owner")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    organization =
      Ash.Seed.seed!(Organization, %{name: "Globex", text_logo: "Globex"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: org_admin.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, _view, html} = live(conn, ~p"/dashboard/organizations")

    assert html =~ "Globex"
    assert html =~ "Org Owner"
    assert html =~ "org-owner@example.com"
  end

  test "org admins are redirected from organizations page", %{conn: conn} do
    user = user!("org-only@example.com")
    organization = Ash.Seed.seed!(Organization, %{name: "Initech", text_logo: "Initech"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: user.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)

    assert {:error, {:live_redirect, %{to: "/dashboard"}}} =
             live(conn, ~p"/dashboard/organizations")
  end

  test "platform owners can access users page", %{conn: conn} do
    owner = user!("platform-users@example.com", "Platform User")
    org_admin = user!("admin-users@example.com", "Admin User")
    plain_user = user!("end-user@example.com", "End User")

    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    organization =
      Ash.Seed.seed!(Organization, %{name: "Umbrella", text_logo: "Umbrella"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: org_admin.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, _view, html} = live(conn, ~p"/dashboard/users")

    assert html =~ "Platform User"
    assert html =~ "Platform owner"
    assert html =~ "Admin User"
    assert html =~ "Org admin"
    assert html =~ "Umbrella"
    assert html =~ "Ban user"
    assert html =~ "Archive user"
    refute html =~ plain_user.email
  end

  test "platform owners can ban and unban users from users page", %{conn: conn} do
    owner = user!("platform-ban-ui@example.com", "Platform Ban User")
    org_admin = user!("admin-ban-ui@example.com", "Admin Ban User")

    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    organization =
      Ash.Seed.seed!(Organization, %{name: "Ban UI Org", text_logo: "Ban UI Org"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: org_admin.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, _html} = live(conn, ~p"/dashboard/users")

    html =
      view
      |> element("button[phx-click='ban_user'][phx-value-id='#{org_admin.id}']")
      |> render_click()

    assert html =~ "User banned."
    assert html =~ "Banned"
    assert html =~ "Unban user"

    html =
      view
      |> element("button[phx-click='unban_user'][phx-value-id='#{org_admin.id}']")
      |> render_click()

    assert html =~ "User unbanned."
    refute html =~ "Banned"
    assert html =~ "Ban user"
  end

  test "platform owners can archive and restore users from users page", %{conn: conn} do
    owner = user!("platform-archive-ui@example.com", "Platform Archive User")
    org_admin = user!("admin-archive-ui@example.com", "Admin Archive User")

    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    organization =
      Ash.Seed.seed!(Organization, %{name: "Archive UI Org", text_logo: "Archive UI Org"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: org_admin.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, _html} = live(conn, ~p"/dashboard/users")

    html =
      view
      |> element("button[phx-click='archive_user'][phx-value-id='#{org_admin.id}']")
      |> render_click()

    assert html =~ "User archived."
    assert html =~ "Restore user"

    html =
      view
      |> element("button[phx-click='restore_user'][phx-value-id='#{org_admin.id}']")
      |> render_click()

    assert html =~ "User restored."
    refute html =~ "Restore user"
    assert html =~ "Archive user"
  end

  test "org admins are redirected from users page", %{conn: conn} do
    user = user!("org-users-only@example.com")
    organization = Ash.Seed.seed!(Organization, %{name: "Initrode", text_logo: "Initrode"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: organization.id,
      user_id: user.id,
      role: :org_admin
    })

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)

    assert {:error, {:live_redirect, %{to: "/dashboard"}}} =
             live(conn, ~p"/dashboard/users")
  end

  defp user!(email, name \\ "Test User") do
    Ash.Seed.seed!(User, %{email: email, name: name})
  end
end
