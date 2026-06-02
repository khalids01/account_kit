defmodule AccountkitWeb.Pages.ApplicationSso.LoginLive do
  use AccountkitWeb, :live_view

  import AccountkitWeb.Features.ApplicationSso.Components

  alias AccountkitWeb.Features.ApplicationSso.{Auth, Clients, Forms}

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign_client(params)
     |> assign(:form, Forms.login_form())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.auth_shell client={@client} title="Sign in to your account" flash={@flash}>
      <.form
        :if={@form_enabled}
        for={@form}
        phx-submit="submit"
        phx-change="validate"
        class="space-y-5"
      >
        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          autocomplete="email"
          required
          phx-debounce="blur"
          placeholder="you@example.com"
        />

        <.password_input
          field={@form[:password]}
          label="Password"
          autocomplete="current-password"
          required
          placeholder="Your password"
        />

        <button type="submit" class="btn btn-primary w-full">Sign in</button>
      </.form>

      <p :if={@form_enabled} class="mt-6 text-center text-sm text-base-content/70">
        Don't have an account?
        <.link navigate={@register_path} class="font-medium text-primary hover:underline">
          Sign up
        </.link>
      </p>
    </.auth_shell>
    """
  end

  @impl true
  def handle_event("validate", %{"sso_login" => params}, socket) do
    {:noreply, assign(socket, :form, Forms.login_form(params))}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("submit", %{"sso_login" => params}, socket) do
    changeset = Forms.login_changeset(params)

    cond do
      not changeset.valid? ->
        {:noreply, assign(socket, :form, to_form(%{changeset | action: :validate}, as: :sso_login))}

      true ->
        case Auth.sign_in(socket.assigns.application, params) do
          {:ok, end_user} ->
            {:noreply, redirect_to_client(socket, end_user)}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, Clients.error_message(reason))}
        end
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
  end

  defp assign_client(socket, %{"token" => token, "redirect_url" => redirect_url} = params)
       when token != "" and redirect_url != "" do
    callback_params = Map.get(params, "callback_params")

    socket =
      assign(socket,
        token: token,
        redirect_url: redirect_url,
        callback_params: callback_params,
        register_path: sso_path("/sso/register", token, redirect_url, callback_params)
      )

    case Clients.validate_client(token, redirect_url) do
      {:ok, application} ->
        socket =
          assign(socket,
            application: application,
            client: Clients.public_client(application),
            form_enabled: application.password_enabled
          )

        if application.password_enabled do
          socket
        else
          put_flash(socket, :error, Clients.error_message(:password_disabled))
        end

      {:error, reason} ->
        socket
        |> assign(application: nil, client: nil, form_enabled: false)
        |> put_flash(:error, Clients.error_message(reason))
    end
  end

  defp assign_client(socket, _params) do
    socket
    |> assign(
      token: nil,
      redirect_url: nil,
      callback_params: nil,
      register_path: nil,
      application: nil,
      client: nil,
      form_enabled: false
    )
    |> put_flash(:error, "Missing required parameters")
  end

  defp redirect_to_client(socket, end_user) do
    redirect(socket,
      external:
        Clients.callback_url(
          socket.assigns.redirect_url,
          socket.assigns.callback_params,
          end_user.__metadata__.token
        )
    )
  end

  defp sso_path(path, token, redirect_url, callback_params) do
    params =
      %{"token" => token, "redirect_url" => redirect_url}
      |> maybe_put_callback_params(callback_params)

    path <> "?" <> URI.encode_query(params)
  end

  defp maybe_put_callback_params(params, value) when value in [nil, ""], do: params
  defp maybe_put_callback_params(params, value), do: Map.put(params, "callback_params", value)
end
