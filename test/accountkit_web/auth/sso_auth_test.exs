defmodule AccountkitWeb.Auth.SsoAuthTest do
  use AccountkitWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Accountkit.Accounts.{EndUser, Organization, SsoApplication}
  alias AccountkitWeb.Features.ApplicationSso.Clients

  describe "client validation" do
    test "valid client token and redirect URL succeeds", %{conn: conn} do
      %{token: token} = sso_application!()

      conn =
        post(conn, "/api/auth/validate-client", %{
          token: token,
          redirectUrl: "http://localhost:5173/callback"
        })

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "invalid client token and invalid redirect URL fail", %{conn: conn} do
      %{token: token} = sso_application!()

      invalid_client =
        post(conn, "/api/auth/validate-client", %{
          token: "not-real",
          redirectUrl: "http://localhost:5173/callback"
        })

      assert %{"error" => "Invalid client token"} = json_response(invalid_client, 401)

      invalid_redirect =
        post(conn, "/api/auth/validate-client", %{
          token: token,
          redirectUrl: "https://evil.example/callback"
        })

      assert %{"error" => "Invalid redirect URL"} = json_response(invalid_redirect, 400)
    end

    test "deactivated apps and disabled password auth fail", %{conn: conn} do
      %{application: inactive, token: inactive_token} = sso_application!()

      inactive
      |> Ash.Changeset.for_update(:deactivate, %{}, authorize?: false)
      |> Ash.update!()

      inactive_response =
        post(conn, "/api/auth/validate-client", %{
          token: inactive_token,
          redirectUrl: "http://localhost:5173/callback"
        })

      assert %{"error" => "Invalid client token"} = json_response(inactive_response, 401)

      %{token: disabled_token} = sso_application!(%{password_enabled: false})

      disabled_response =
        post(conn, "/api/rest/auth/login", %{
          email: "user@example.com",
          password: "password123",
          token: disabled_token,
          redirectUrl: "http://localhost:5173/callback"
        })

      assert %{
               "success" => false,
               "code" => "PASSWORD_DISABLED"
             } = json_response(disabled_response, 400)
    end

    test "origin validation supports exact origins and wildcard subdomains", %{conn: conn} do
      %{token: token} =
        sso_application!(%{
          allowed_origins: ["http://localhost:5173", "*.tenant.example.com"]
        })

      exact =
        post(conn, "/api/auth/validate-client", %{
          token: token,
          redirectUrl: "http://localhost:5173/callback",
          clientOrigin: "http://localhost:5173"
        })

      assert %{"success" => true} = json_response(exact, 200)

      wildcard =
        post(conn, "/api/auth/validate-client", %{
          token: token,
          redirectUrl: "http://localhost:5173/callback",
          clientOrigin: "https://app.tenant.example.com"
        })

      assert %{"success" => true} = json_response(wildcard, 200)
    end
  end

  describe "callback URLs" do
    test "preserves existing params and prevents passthrough auth_token override" do
      url =
        Clients.callback_url(
          "http://localhost:5173/callback?existing=kept",
          "auth_token=bad&campaign=sso",
          "good-token"
        )

      query = URI.parse(url).query |> URI.decode_query()

      assert query["existing"] == "kept"
      assert query["campaign"] == "sso"
      assert query["auth_token"] == "good-token"
      assert query["expires_in"] == "0"
      refute url =~ "auth_token=bad"
    end
  end

  describe "REST auth" do
    test "login returns legacy-compatible token, user, and client", %{conn: conn} do
      %{token: token} = sso_application!()
      end_user!("login@example.com", "Login User", "password123", application_for_token(token))

      conn =
        post(conn, "/api/rest/auth/login", %{
          email: "login@example.com",
          password: "password123",
          token: token,
          redirectUrl: "http://localhost:5173/callback"
        })

      assert %{
               "success" => true,
               "token" => auth_token,
               "expires_in" => expires_in,
               "user" => %{"email" => "login@example.com", "name" => "Login User"},
               "client" => %{"name" => "Test App"}
             } = json_response(conn, 200)

      assert is_binary(auth_token)
      assert is_integer(expires_in)
      assert expires_in > 0
    end

    test "register creates a user and returns the same response shape", %{conn: conn} do
      %{token: token} = sso_application!()

      conn =
        post(conn, "/api/rest/auth/register", %{
          name: "Register User",
          email: "register@example.com",
          password: "password123",
          token: token,
          redirectUrl: "http://localhost:5173/callback"
        })

      assert %{
               "success" => true,
               "token" => auth_token,
               "expires_in" => expires_in,
               "user" => %{"email" => "register@example.com", "name" => "Register User"},
               "client" => %{"name" => "Test App"}
             } = json_response(conn, 200)

      assert is_binary(auth_token)
      assert is_integer(expires_in)
      assert expires_in > 0
    end

    test "user endpoint accepts bearer tokens and rejects missing tokens", %{conn: conn} do
      %{token: token} = sso_application!()

      end_user!(
        "profile@example.com",
        "Profile User",
        "password123",
        application_for_token(token)
      )

      login_conn =
        post(conn, "/api/rest/auth/login", %{
          email: "profile@example.com",
          password: "password123",
          token: token,
          redirectUrl: "http://localhost:5173/callback"
        })

      %{"token" => auth_token} = json_response(login_conn, 200)

      profile_conn =
        conn
        |> recycle()
        |> put_req_header("authorization", "Bearer #{auth_token}")
        |> get("/api/rest/auth/user")

      assert %{
               "success" => true,
               "user" => %{"email" => "profile@example.com"}
             } = json_response(profile_conn, 200)

      missing_conn =
        conn
        |> recycle()
        |> put_req_header("origin", "http://localhost:5174")
        |> get("/api/rest/auth/user")

      assert %{"success" => false, "code" => "INVALID_TOKEN"} = json_response(missing_conn, 401)

      assert get_resp_header(missing_conn, "access-control-allow-origin") == [
               "http://localhost:5174"
             ]
    end
  end

  describe "SSO LiveViews" do
    test "normal login still shows magic-link login", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/login")

      assert html =~ "Send magic link"
      assert html =~ "Sign in to AccountKit"
    end

    test "SSO login and register render password forms with client branding", %{conn: conn} do
      %{token: token} = sso_application!()
      query = URI.encode_query(%{token: token, redirect_url: "http://localhost:5173/callback"})

      {:ok, _view, login_html} = live(conn, "/sso/login?#{query}")

      assert login_html =~ "Test App"
      assert login_html =~ "Sign in to your account"
      assert login_html =~ "type=\"password\""

      {:ok, _view, register_html} = live(conn, "/sso/register?#{query}")

      assert register_html =~ "Test App"
      assert register_html =~ "Create account"
      assert register_html =~ "type=\"password\""
    end
  end

  defp sso_application!(attrs \\ %{}) do
    organization = Ash.Seed.seed!(Organization, %{name: "SSO Org", text_logo: "SSO"})

    attrs =
      Map.merge(
        %{
          organization_id: organization.id,
          name: "Test App",
          allowed_origins: ["http://localhost:5173"],
          redirect_urls: ["http://localhost:5173/callback"],
          password_enabled: true
        },
        attrs
      )

    application =
      SsoApplication
      |> Ash.Changeset.for_create(:create, attrs, authorize?: false)
      |> Ash.create!()
      |> Ash.load!(:client_token, authorize?: false)

    %{application: application, token: application.client_token}
  end

  defp end_user!(email, name, password, application) do
    EndUser
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{
        sso_application_id: application.id,
        name: name,
        email: email,
        password: password,
        password_confirmation: password
      },
      authorize?: false
    )
    |> Ash.create!()
  end

  defp application_for_token(token) do
    SsoApplication
    |> Ash.Query.for_read(
      :get_by_client_token_hash,
      %{client_token_hash: SsoApplication.hash_token(token)},
      authorize?: false
    )
    |> Ash.read_one!()
  end
end
