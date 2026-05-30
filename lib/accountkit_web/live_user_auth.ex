defmodule AccountkitWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use AccountkitWeb, :verified_routes

  alias Accountkit.Accounts.Authorization

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {AccountkitWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)}
  end

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    cond do
      is_nil(socket.assigns[:current_user]) ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}

      Authorization.banned?(socket.assigns.current_user) ->
        {:halt, banned_redirect(socket)}

      true ->
        {:cont, socket}
    end
  end

  def on_mount(:dashboard_user_required, _params, _session, socket) do
    cond do
      is_nil(socket.assigns[:current_user]) ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}

      Authorization.banned?(socket.assigns.current_user) ->
        {:halt, banned_redirect(socket)}

      Authorization.dashboard_user?(socket.assigns.current_user) ->
        {:cont, socket}

      true ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/onboarding/organization")}
    end
  end

  def on_mount(:platform_owner_required, _params, _session, socket) do
    cond do
      is_nil(socket.assigns[:current_user]) ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}

      Authorization.banned?(socket.assigns.current_user) ->
        {:halt, banned_redirect(socket)}

      Authorization.platform_owner?(socket.assigns.current_user) ->
        {:cont, socket}

      true ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    end
  end

  def on_mount(:assign_client_ip, _params, session, socket) do
    ip =
      AccountkitWeb.Auth.RemoteIp.from_session(session)

    {:cont, assign(socket, :client_ip, ip)}
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    cond do
      is_nil(socket.assigns[:current_user]) ->
        {:cont, assign(socket, :current_user, nil)}

      Authorization.banned?(socket.assigns.current_user) ->
        {:halt, banned_redirect(socket)}

      true ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    end
  end

  defp banned_redirect(socket) do
    socket
    |> Phoenix.LiveView.put_flash(
      :error,
      "This account has been banned. Contact the platform owner for access."
    )
    |> Phoenix.LiveView.redirect(to: ~p"/sign-out")
  end
end
