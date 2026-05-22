defmodule AccountkitWeb.Auth.DashboardAccessTest do
  use AccountkitWeb.ConnCase

  import AshAuthentication.Plug.Helpers

  alias Accountkit.Accounts.{PlatformRole, User}

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

    assert redirected_to(conn) == ~p"/"
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

  defp user!(email) do
    Ash.Seed.seed!(User, %{email: email, name: "Test User"})
  end
end
