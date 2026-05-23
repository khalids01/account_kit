defmodule AccountkitWeb.Auth.DashboardAccessTest do
  use AccountkitWeb.ConnCase

  import AshAuthentication.Plug.Helpers
  import Phoenix.LiveViewTest

  alias Accountkit.Accounts.{Organization, OrganizationMembership, PlatformRole, User}

  test "anonymous users are redirected from control-plane routes", %{conn: conn} do
    conn = get(conn, ~p"/admin/rate-limits")

    assert redirected_to(conn) == ~p"/login"
  end

  test "signed-in users without a scoped role are redirected from control-plane routes", %{conn: conn} do
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

  defp user!(email, name \\ "Test User") do
    Ash.Seed.seed!(User, %{email: email, name: name})
  end
end
