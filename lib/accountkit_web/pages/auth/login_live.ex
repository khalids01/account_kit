defmodule AccountkitWeb.Pages.Auth.LoginLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.User
  alias Accountkit.RateLimit
  alias Accountkit.Sso
  alias AccountkitWeb.Auth.RemoteIp
  alias AccountkitWeb.Features.Auth.LoginForm

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign_sso(params)
     |> assign_form(%{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.home flash={@flash} current_scope={nil}>
      <section
        :if={@sso_mode?}
        class="mx-auto flex min-h-[calc(100vh-4rem)] max-w-md items-center px-6 py-16"
      >
        <div class="w-full rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm">
          <div class="mb-8 text-center">
            <img
              :if={@sso_client && @sso_client.logoUrl}
              src={@sso_client.logoUrl}
              alt={@sso_client.name <> " logo"}
              class="mx-auto mb-4 max-h-16 max-w-36 object-contain"
            />
            <p :if={@sso_client} class="text-sm font-medium text-base-content/60">
              {@sso_client.name}
            </p>
            <h1 class="mt-3 text-2xl font-bold tracking-tight">Sign in to your account</h1>
          </div>

          <div
            :if={@sso_error}
            class="mb-5 rounded-xl border border-error/30 bg-error/10 px-4 py-3 text-sm text-error"
          >
            {@sso_error}
          </div>

          <.form
            :if={is_nil(@sso_error)}
            for={@sso_form}
            phx-submit="sso_submit"
            class="space-y-5"
          >
            <.input
              field={@sso_form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
              class="mt-2 w-full !px-2 !h-10"
              placeholder="you@example.com"
            />

            <.input
              field={@sso_form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
              required
              class="mt-2 w-full !px-2 !h-10"
              placeholder="Your password"
            />

            <button type="submit" class="btn btn-primary w-full">
              Sign in
            </button>
          </.form>

          <p :if={is_nil(@sso_error)} class="mt-6 text-center text-sm text-base-content/70">
            Don't have an account?
            <.link navigate={@sso_register_path} class="font-medium text-primary hover:underline">
              Sign up
            </.link>
          </p>
        </div>
      </section>

      <section
        :if={!@sso_mode?}
        class="mx-auto flex min-h-[calc(100vh-4rem)] max-w-md items-center px-6 py-16"
      >
        <div class="w-full rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm">
          <div class="mb-8 text-center">
            <.logo class="justify-center" />
            <h1 class="mt-6 text-2xl font-bold tracking-tight">Sign in to AccountKit</h1>
            <p class="mt-2 text-sm text-base-content/70">
              Enter your email and we will send you a magic sign-in link.
            </p>
          </div>

          <.form for={@form} phx-submit="submit" phx-change="validate" class="space-y-5">
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
              phx-debounce="blur"
              class="mt-2 w-full !px-2 !h-10"
              placeholder="you@example.com"
            />

            <button type="submit" class="btn btn-primary w-full">
              Send magic link
            </button>
          </.form>

          <p class="mt-6 text-center text-sm text-base-content/70">
            New to AccountKit?
            <.link navigate={~p"/register"} class="font-medium text-primary hover:underline">
              Create an account
            </.link>
          </p>
        </div>
      </section>
    </Layouts.home>
    """
  end

  @impl true
  def handle_event("validate", %{"login" => params}, socket) do
    {:noreply, assign_form(socket, params, :validate)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"login" => params}, socket) do
    changeset = LoginForm.changeset(params, action: :submit)
    ip = RemoteIp.from_socket(socket)
    user_result = if changeset.valid?, do: get_user(changeset), else: {:ok, nil}

    cond do
      not changeset.valid? ->
        {:noreply,
         socket
         |> put_flash(:error, first_error(changeset))
         |> assign_form(changeset)}

      RateLimit.denied?(:magic_link_sign_in,
        ip: ip,
        email: Ecto.Changeset.get_field(changeset, :email)
      ) ->
        {:noreply, put_flash(socket, :error, "Too many attempts. Please wait and try again.")}

      banned_user_result?(user_result) ->
        message = "This account has been banned. Contact the platform owner for access."

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> assign_form(Ecto.Changeset.add_error(changeset, :email, message))}

      user_found?(user_result) ->
        case request_magic_link(changeset) do
          :ok ->
            {:noreply,
             socket
             |> put_flash(:info, "Check your email for a magic sign-in link.")
             |> assign_form(%{})}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Could not send the magic link. Try again.")}
        end

      true ->
        message = "No account exists for that email. Create an account first."

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> assign_form(Ecto.Changeset.add_error(changeset, :email, message))}
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
  end

  @impl true
  def handle_event("sso_submit", %{"sso_login" => params}, socket) do
    case sso_sign_in(params, socket.assigns.sso_application) do
      {:ok, user} ->
        {:noreply,
         redirect(socket,
           external:
             Sso.callback_url(
               socket.assigns.sso_redirect_url,
               socket.assigns.sso_callback_params,
               user.__metadata__.token
             )
         )}

      {:error, message} ->
        {:noreply, assign(socket, :sso_error, message)}
    end
  end

  def handle_event("sso_submit", _params, socket) do
    {:noreply, assign(socket, :sso_error, "Something went wrong. Please try again.")}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: :login))
  end

  defp assign_form(socket, params) when is_map(params) do
    assign_form(socket, params, nil)
  end

  defp assign_form(socket, params, action) when is_map(params) do
    assign_form(socket, LoginForm.changeset(params, action: action))
  end

  defp get_user(%Ecto.Changeset{} = changeset) do
    email = Ecto.Changeset.get_field(changeset, :email)

    get_user(email)
  end

  defp get_user(email) do
    User
    |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
    |> Ash.read_one()
  end

  defp banned_user?(%User{banned_at: %DateTime{}}), do: true
  defp banned_user?(_user), do: false

  defp banned_user_result?({:ok, user}), do: banned_user?(user)
  defp banned_user_result?(_result), do: false

  defp user_found?({:ok, %User{}}), do: true
  defp user_found?(_result), do: false

  defp request_magic_link(%Ecto.Changeset{} = changeset) do
    email = Ecto.Changeset.get_field(changeset, :email)

    User
    |> Ash.ActionInput.for_action(:request_magic_link, %{email: email}, authorize?: false)
    |> Ash.run_action()
  end

  defp first_error(%Ecto.Changeset{errors: [{_field, {message, _opts}} | _]}), do: message
  defp first_error(_changeset), do: "Please fix the highlighted fields."

  defp assign_sso(socket, %{"token" => token, "redirect_url" => redirect_url} = params)
       when token != "" and redirect_url != "" do
    callback_params = Map.get(params, "callback_params")

    socket =
      socket
      |> assign(:sso_mode?, true)
      |> assign(:sso_token, token)
      |> assign(:sso_redirect_url, redirect_url)
      |> assign(:sso_callback_params, callback_params)
      |> assign(:sso_form, to_form(%{}, as: :sso_login))
      |> assign(:sso_register_path, sso_path("/register", token, redirect_url, callback_params))

    case Sso.validate_client(token, redirect_url) do
      {:ok, application} ->
        assign(socket,
          sso_application: application,
          sso_client: Sso.public_client(application),
          sso_error: nil
        )

      {:error, reason} ->
        assign(socket,
          sso_application: nil,
          sso_client: nil,
          sso_error: Sso.error_message(reason)
        )
    end
  end

  defp assign_sso(socket, _params) do
    assign(socket,
      sso_mode?: false,
      sso_application: nil,
      sso_client: nil,
      sso_error: nil,
      sso_token: nil,
      sso_redirect_url: nil,
      sso_callback_params: nil,
      sso_form: to_form(%{}, as: :sso_login),
      sso_register_path: nil
    )
  end

  defp sso_sign_in(_params, nil), do: {:error, "Invalid client or redirect URL"}

  defp sso_sign_in(_params, %{password_enabled: false}),
    do: {:error, "Password authentication is disabled for this client"}

  defp sso_sign_in(params, _application) do
    User
    |> Ash.Query.for_read(
      :sign_in_with_password,
      %{email: params["email"], password: params["password"]},
      authorize?: false
    )
    |> Ash.read_one()
    |> case do
      {:ok, %User{} = user} -> {:ok, user}
      _error -> {:error, "Invalid email or password"}
    end
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
