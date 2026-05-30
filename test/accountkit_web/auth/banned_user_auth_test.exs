defmodule AccountkitWeb.Auth.BannedUserAuthTest do
  use AccountkitWeb.ConnCase

  import AshAuthentication.Plug.Helpers
  import Phoenix.LiveViewTest

  alias Accountkit.Accounts.User
  alias AccountkitWeb.AuthController

  test "banned users cannot request a magic sign-in link", %{conn: conn} do
    user!("banned-login@example.com", banned_at: DateTime.utc_now())

    {:ok, view, _html} = live(conn, ~p"/login")

    html =
      view
      |> form("form", login: %{email: "banned-login@example.com"})
      |> render_submit()

    assert html =~ "This account has been banned"
  end

  test "banned users are rejected during auth success", %{conn: conn} do
    user = user!("banned-success@example.com", banned_at: DateTime.utc_now())

    conn =
      conn
      |> init_test_session(%{})
      |> AuthController.success(:magic_link, user, "token")

    assert redirected_to(conn) == ~p"/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "This account has been banned"
  end

  test "archived users can still complete auth success", %{conn: conn} do
    user = user!("archived-success@example.com", archived_at: DateTime.utc_now())

    conn =
      conn
      |> init_test_session(%{})
      |> AuthController.success(:magic_link, user, "token")

    assert redirected_to(conn) == ~p"/onboarding/organization"
  end

  test "banned signed-in users are redirected to sign out from guarded liveviews", %{conn: conn} do
    user = user!("banned-guard@example.com", banned_at: DateTime.utc_now())

    conn =
      conn
      |> init_test_session(%{})
      |> store_in_session(user)

    assert {:error, {:redirect, %{to: "/sign-out"}}} = live(conn, ~p"/profile")
  end

  defp user!(email, attrs \\ []) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.merge(%{email: email, name: "Test User"})

    Ash.Seed.seed!(User, attrs)
  end
end
