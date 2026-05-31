defmodule AccountkitWeb.Auth.DashboardAccessTest do
  use AccountkitWeb.ConnCase

  import AshAuthentication.Plug.Helpers
  import Phoenix.LiveViewTest

  alias Accountkit.Accounts.{
    ApiKey,
    Organization,
    OrganizationMembership,
    PlatformRole,
    SsoApplication,
    User
  }

  alias Accountkit.Settings.RateLimitPolicy

  require Ash.Query

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

  test "platform owners can list and filter applications by organization", %{conn: conn} do
    owner = user!("platform-apps@example.com", "Platform Apps")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    alpha = Ash.Seed.seed!(Organization, %{name: "Alpha Org", text_logo: "Alpha"})
    beta = Ash.Seed.seed!(Organization, %{name: "Beta Org", text_logo: "Beta"})

    create_application!(owner, alpha, %{name: "Alpha Portal"})
    create_application!(owner, beta, %{name: "Beta Console", google_enabled: true})

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, html} = live(conn, ~p"/dashboard/applications")

    assert html =~ "Applications"
    assert html =~ "applications-card-grid"
    assert html =~ "Alpha Portal"
    assert html =~ "Beta Console"
    assert html =~ "Alpha Org"
    assert html =~ "Beta Org"
    assert html =~ "Google: Needs config"
    refute html =~ "<table"

    html =
      view
      |> form("form[phx-change='filter_organization']", %{organization_id: alpha.id})
      |> render_change()

    assert html =~ "Alpha Portal"
    refute html =~ "Beta Console"
  end

  test "org admins see and create applications only for their organization", %{conn: conn} do
    platform_owner = user!("platform-for-org-apps@example.com", "Platform Apps Owner")
    org_admin = user!("org-apps-admin@example.com", "Org Apps Admin")

    Ash.Seed.seed!(PlatformRole, %{user_id: platform_owner.id, role: :platform_owner})

    own_org = Ash.Seed.seed!(Organization, %{name: "Own Apps Org", text_logo: "Own"})
    other_org = Ash.Seed.seed!(Organization, %{name: "Other Apps Org", text_logo: "Other"})

    Ash.Seed.seed!(OrganizationMembership, %{
      organization_id: own_org.id,
      user_id: org_admin.id,
      role: :org_admin
    })

    create_application!(org_admin, own_org, %{name: "Own Portal"})
    create_application!(platform_owner, other_org, %{name: "Other Portal"})

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(org_admin)

    {:ok, view, html} = live(conn, ~p"/dashboard/applications")

    assert html =~ "Own Portal"
    assert html =~ "Own Apps Org"
    refute html =~ "Other Portal"
    refute html =~ "Choose organization"

    view
    |> element("button", "Create")
    |> render_click()

    html =
      view
      |> form("#create-application-form", %{
        application: %{
          name: "Org Admin App",
          redirect_urls: ["https://example.com/callback", "https://example.com/return"],
          allowed_origins: ["https://example.com"],
          password_enabled: "true",
          magic_link_enabled: "true"
        }
      })
      |> render_submit()

    assert html =~ "Application created."
    assert html =~ "Org Admin App"
    assert html =~ "Own Apps Org"

    [created] =
      SsoApplication
      |> Ash.Query.for_read(:list_for_organization, %{organization_id: own_org.id},
        actor: org_admin
      )
      |> Ash.read!()
      |> Enum.filter(&(&1.name == "Org Admin App"))

    assert created.organization_id == own_org.id
    assert byte_size(created.client_token_hash) == 32
    assert created.redirect_urls == ["https://example.com/callback", "https://example.com/return"]
  end

  test "signed-in users without a scoped role are redirected from applications page", %{
    conn: conn
  } do
    user = user!("plain-apps@example.com")

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)

    assert {:error, {:redirect, %{to: "/onboarding/organization"}}} =
             live(conn, ~p"/dashboard/applications")
  end

  test "application token reveal, rotation, and hash lookup work", %{conn: conn} do
    owner = user!("platform-app-token@example.com", "Platform Token Owner")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    organization = Ash.Seed.seed!(Organization, %{name: "Token Org", text_logo: "Token"})

    application =
      create_application!(owner, organization, %{
        name: "Token App",
        redirect_urls: ["https://token.example/callback"]
      })

    original_hash = application.client_token_hash
    original_token = loaded_client_token!(application, owner)

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, html} = live(conn, ~p"/dashboard/applications")

    assert html =~ "Token App"
    refute html =~ original_token

    html =
      view
      |> element("button[phx-click='view_application'][phx-value-id='#{application.id}']")
      |> render_click()

    assert html =~ "Application profile"
    assert html =~ "Hidden"

    html =
      view
      |> element("button[phx-click='reveal_token'][phx-value-id='#{application.id}']")
      |> render_click()

    assert html =~ original_token

    found =
      SsoApplication
      |> Ash.Query.for_read(:get_by_client_token_hash, %{
        client_token_hash: SsoApplication.hash_token(original_token)
      })
      |> Ash.read_one!(authorize?: false)

    assert found.id == application.id

    html =
      view
      |> element("button[phx-click='rotate_token'][phx-value-id='#{application.id}']")
      |> render_click()

    assert html =~ "Application token rotated."

    rotated =
      application.id
      |> application_by_id!()
      |> Ash.load!(:client_token, actor: owner)

    assert rotated.client_token =~ ~r/\A[0-9a-f]{64}\z/
    refute rotated.client_token == original_token
    refute rotated.client_token_hash == original_hash
    assert html =~ rotated.client_token
  end

  test "application archive and deactivate flows update status", %{conn: conn} do
    owner = user!("platform-app-status@example.com", "Platform Status Owner")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    organization = Ash.Seed.seed!(Organization, %{name: "Status Org", text_logo: "Status"})
    application = create_application!(owner, organization, %{name: "Status App"})

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, html} = live(conn, ~p"/dashboard/applications")

    assert html =~ "Status App"
    assert html =~ "Active"

    html =
      view
      |> element("button[phx-click='archive_application'][phx-value-id='#{application.id}']")
      |> render_click()

    assert html =~ "Application archived."
    assert html =~ "Archived"
    assert application_by_id!(application.id).archived_at

    html =
      view
      |> element(
        "button[phx-click='request_deactivate_application'][phx-value-id='#{application.id}']"
      )
      |> render_click()

    assert html =~ "Deactivate Status App?"
    refute application_by_id!(application.id).deactivated_at

    html =
      view
      |> element(
        "button[phx-click='confirm_deactivate_application'][phx-value-id='#{application.id}']"
      )
      |> render_click()

    assert html =~ "Application deactivated."
    assert html =~ "Deactivated"
    assert application_by_id!(application.id).deactivated_at

    html =
      view
      |> element("button[phx-click='activate_application'][phx-value-id='#{application.id}']")
      |> render_click()

    assert html =~ "Application activated."
    refute application_by_id!(application.id).deactivated_at
  end

  test "platform owners can create and revoke their own API keys", %{conn: conn} do
    owner = user!("platform-api-keys@example.com", "API Key Owner")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, html} = live(conn, ~p"/dashboard/api-keys")

    assert html =~ "API keys"
    assert html =~ "No API keys yet."

    expires_on =
      Date.utc_today()
      |> Date.add(7)
      |> Date.to_iso8601()

    html =
      view
      |> form("form[phx-submit='create_api_key']", %{api_key: %{expires_on: expires_on}})
      |> render_submit()

    assert html =~ "API key created."
    assert html =~ "accountkit_"
    assert html =~ "Copy it now"
    assert html =~ "Valid"

    [api_key] = api_keys_for_user(owner)

    html =
      view
      |> element("button[phx-click='revoke_api_key'][phx-value-id='#{api_key.id}']")
      |> render_click()

    assert html =~ "API key revoked."
    assert html =~ "No API keys yet."
    assert api_keys_for_user(owner) == []
  end

  test "org admins are redirected from API keys page", %{conn: conn} do
    user = user!("org-api-keys-only@example.com")
    organization = Ash.Seed.seed!(Organization, %{name: "API Key Org", text_logo: "API Key Org"})

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
             live(conn, ~p"/dashboard/api-keys")
  end

  test "platform owners can update rate limit settings", %{conn: conn} do
    owner = user!("platform-settings@example.com", "Settings Owner")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    policy = rate_limit_policy!("magic_link_sign_in_ip")

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(owner)

    {:ok, view, html} = live(conn, ~p"/dashboard/settings")

    assert html =~ "Settings"
    assert html =~ "Magic link sign in"
    assert html =~ "magic_link_sign_in_ip"

    html =
      view
      |> form("form[phx-value-id='#{policy.id}']", %{
        policy: %{
          limit: "9",
          period_seconds: "120",
          enabled: "true",
          description: "Updated sign-in limit"
        }
      })
      |> render_submit()

    assert html =~ "Saved magic_link_sign_in_ip."

    updated_policy = rate_limit_policy!("magic_link_sign_in_ip")

    assert updated_policy.limit == 9
    assert updated_policy.period_seconds == 120
    assert updated_policy.enabled
    assert updated_policy.description == "Updated sign-in limit"
  end

  test "org admins are redirected from settings page", %{conn: conn} do
    user = user!("org-settings-only@example.com")

    organization =
      Ash.Seed.seed!(Organization, %{name: "Settings Org", text_logo: "Settings Org"})

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
             live(conn, ~p"/dashboard/settings")
  end

  defp user!(email, name \\ "Test User") do
    Ash.Seed.seed!(User, %{email: email, name: name})
  end

  defp api_keys_for_user(user) do
    ApiKey
    |> Ash.Query.for_read(:list_for_user, %{user_id: user.id})
    |> Ash.read!(authorize?: false)
  end

  defp rate_limit_policy!(key) do
    RateLimitPolicy
    |> Ash.Query.for_read(:list_all, %{})
    |> Ash.read!(authorize?: false)
    |> Enum.find(&(&1.key == key))
  end

  defp create_application!(actor, organization, attrs) do
    attrs =
      %{
        organization_id: organization.id,
        name: "Test Application",
        redirect_urls: ["https://example.com/callback"],
        allowed_origins: ["https://example.com"],
        password_enabled: true,
        magic_link_enabled: true
      }
      |> Map.merge(attrs)

    SsoApplication
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create!()
  end

  defp loaded_client_token!(application, actor) do
    application
    |> Ash.load!(:client_token, actor: actor)
    |> Map.fetch!(:client_token)
  end

  defp application_by_id!(id) do
    SsoApplication
    |> Ash.Query.for_read(:read, %{})
    |> Ash.Query.filter(id == ^id)
    |> Ash.read_one!(authorize?: false)
  end
end
