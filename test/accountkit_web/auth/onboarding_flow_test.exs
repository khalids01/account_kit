defmodule AccountkitWeb.Auth.OnboardingFlowTest do
  use AccountkitWeb.ConnCase

  import AshAuthentication.Plug.Helpers
  import Phoenix.LiveViewTest

  alias Accountkit.Accounts.{Authorization, PlatformRole, User}

  test "signed-in users without a scoped role can create an organization", %{conn: conn} do
    user = user!("founder@example.com")

    {:ok, view, _html} =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)
      |> live(~p"/onboarding/organization")

    view
    |> form("#organization-onboarding-form",
      organization: %{name: "Founder Co", text_logo: "Founder"}
    )
    |> render_submit()

    assert_redirect(view, ~p"/dashboard")
    assert Authorization.dashboard_user?(user)
  end

  test "platform owners bypass organization onboarding", %{conn: conn} do
    user = user!("platform-owner@example.com")
    Ash.Seed.seed!(PlatformRole, %{user_id: user.id, role: :platform_owner})

    assert {:error, {:live_redirect, %{to: "/dashboard"}}} =
             conn
             |> init_test_session(%{})
             |> store_in_session(user)
             |> live(~p"/onboarding/organization")
  end

  defp user!(email) do
    Ash.Seed.seed!(User, %{email: email, name: "Test User"})
  end
end
