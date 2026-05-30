defmodule AccountkitWeb.AuthController do
  use AccountkitWeb, :controller
  use AshAuthentication.Phoenix.Controller

  alias Accountkit.Accounts.{Authorization, PlatformOwnerBootstrap}

  def success(conn, activity, user, _token) do
    return_to = get_session(conn, :return_to)

    if Authorization.banned?(user) do
      conn
      |> delete_session(:return_to)
      |> put_flash(:error, "This account has been banned. Contact the platform owner for access.")
      |> redirect(to: ~p"/login")
    else
      PlatformOwnerBootstrap.grant_if_configured_user(user)

      message =
        case activity do
          {:confirm_new_user, :confirm} -> "Your email address has now been confirmed"
          {:password, :reset} -> "Your password has successfully been reset"
          _ -> "You are now signed in"
        end

      conn
      |> delete_session(:return_to)
      |> store_in_session(user)
      # If your resource has a different name, update the assign name here (i.e :current_admin)
      |> assign(:current_user, user)
      |> put_flash(:info, message)
      |> redirect(to: signed_in_path(return_to, user))
    end
  end

  def failure(conn, activity, reason) do
    message =
      case {activity, reason} do
        {_,
         %AshAuthentication.Errors.AuthenticationFailed{
           caused_by: %Ash.Error.Forbidden{
             errors: [%AshAuthentication.Errors.CannotConfirmUnconfirmedUser{}]
           }
         }} ->
          """
          You have already signed in another way, but have not confirmed your account.
          You can confirm your account using the link we sent to you, or by resetting your password.
          """

        _ ->
          "Incorrect email or password"
      end

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/login")
  end

  def redirect_to_login(conn, _params) do
    redirect(conn, to: ~p"/login")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session(:accountkit)
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: return_to)
  end

  defp signed_in_path(return_to, user) do
    cond do
      safe_return_to?(return_to) ->
        return_to

      Authorization.dashboard_user?(user) ->
        ~p"/dashboard"

      true ->
        ~p"/onboarding/organization"
    end
  end

  defp safe_return_to?(return_to) when is_binary(return_to) do
    String.starts_with?(return_to, "/") and not String.starts_with?(return_to, "//")
  end

  defp safe_return_to?(_return_to), do: false
end
