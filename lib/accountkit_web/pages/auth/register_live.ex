defmodule AccountkitWeb.Pages.Auth.RegisterLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.User
  alias Accountkit.RateLimit
  alias Accountkit.Sso
  alias AccountkitWeb.Auth.RemoteIp
  alias AccountkitWeb.Features.Auth.RegisterForm

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create account")
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
            <h1 class="mt-3 text-2xl font-bold tracking-tight">Create account</h1>
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
              field={@sso_form[:name]}
              type="text"
              label="Name"
              autocomplete="name"
              required
              class="mt-2 w-full"
              placeholder="Khalid"
            />

            <.input
              field={@sso_form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
              class="mt-2 w-full"
              placeholder="you@example.com"
            />

            <.input
              field={@sso_form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
              required
              class="mt-2 w-full"
              placeholder="At least 8 characters"
            />

            <button type="submit" class="btn btn-primary w-full">
              Create account
            </button>
          </.form>

          <p :if={is_nil(@sso_error)} class="mt-6 text-center text-sm text-base-content/70">
            Already have an account?
            <.link navigate={@sso_login_path} class="font-medium text-primary hover:underline">
              Sign in
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
            <h1 class="mt-6 text-2xl font-bold tracking-tight">Create your AccountKit account</h1>
            <p class="mt-2 text-sm text-base-content/70">
              Tell us who you are and we will send a magic signup link.
            </p>
          </div>

          <.form for={@form} phx-submit="submit" phx-change="validate" class="space-y-5">
            <.input
              field={@form[:name]}
              type="text"
              label="Name"
              autocomplete="name"
              required
              phx-debounce="blur"
              class="mt-2 w-full"
              placeholder="Khalid"
            />

            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
              phx-debounce="blur"
              class="mt-2 w-full"
              placeholder="you@example.com"
            />

            <button type="submit" class="btn btn-primary w-full">
              Send signup link
            </button>
          </.form>

          <p class="mt-6 text-center text-sm text-base-content/70">
            Already have an account?
            <.link navigate={~p"/login"} class="font-medium text-primary hover:underline">
              Sign in
            </.link>
          </p>
        </div>
      </section>
    </Layouts.home>
    """
  end

  @impl true
  def handle_event("validate", %{"register" => params}, socket) do
    {:noreply, assign_form(socket, params, :validate)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"register" => params}, socket) do
    changeset = RegisterForm.changeset(params, action: :submit)
    ip = RemoteIp.from_socket(socket)

    cond do
      not changeset.valid? ->
        {:noreply,
         socket
         |> put_flash(:error, first_error(changeset))
         |> assign_form(changeset)}

      RateLimit.denied?(:magic_link_sign_up,
        ip: ip,
        email: Ecto.Changeset.get_field(changeset, :email)
      ) ->
        {:noreply, put_flash(socket, :error, "Too many attempts. Please wait and try again.")}

      user_exists?(changeset) ->
        message = "An account already exists for that email. Sign in instead."

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> assign_form(Ecto.Changeset.add_error(changeset, :email, message))}

      true ->
        case request_signup_magic_link(changeset) do
          :ok ->
            {:noreply,
             put_flash(
               socket,
               :info,
               "Check your email for a magic signup link. Your account will be created when you open it."
             )}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Could not send the signup link. Try again.")}
        end
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
  end

  @impl true
  def handle_event("sso_submit", %{"sso_register" => params}, socket) do
    case sso_register(params, socket.assigns.sso_application) do
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
    assign(socket, :form, to_form(changeset, as: :register))
  end

  defp assign_form(socket, params) when is_map(params) do
    assign_form(socket, params, nil)
  end

  defp assign_form(socket, params, action) when is_map(params) do
    assign_form(socket, RegisterForm.changeset(params, action: action))
  end

  defp user_exists?(%Ecto.Changeset{} = changeset) do
    email = Ecto.Changeset.get_field(changeset, :email)

    case get_user(email) do
      {:ok, %User{}} -> true
      _ -> false
    end
  end

  defp get_user(email) do
    User
    |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
    |> Ash.read_one()
  end

  defp request_signup_magic_link(%Ecto.Changeset{} = changeset) do
    name = Ecto.Changeset.get_field(changeset, :name)
    email = Ecto.Changeset.get_field(changeset, :email)

    User
    |> Ash.ActionInput.for_action(
      :request_signup_magic_link,
      %{name: name, email: email},
      authorize?: false
    )
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
      |> assign(:sso_form, to_form(%{}, as: :sso_register))
      |> assign(:sso_login_path, sso_path("/login", token, redirect_url, callback_params))

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
      sso_form: to_form(%{}, as: :sso_register),
      sso_login_path: nil
    )
  end

  defp sso_register(_params, nil), do: {:error, "Invalid client or redirect URL"}

  defp sso_register(_params, %{password_enabled: false}),
    do: {:error, "Password authentication is disabled for this client"}

  defp sso_register(%{"password" => password}, _application)
       when not is_binary(password) or byte_size(password) < 8 do
    {:error, "Password must be at least 8 characters long"}
  end

  defp sso_register(params, _application) do
    User
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{
        name: params["name"],
        email: params["email"],
        password: params["password"],
        password_confirmation: params["password"]
      },
      authorize?: false
    )
    |> Ash.create()
    |> case do
      {:ok, %User{} = user} -> {:ok, user}
      {:error, error} -> {:error, register_error_message(error)}
    end
  end

  defp register_error_message(error) do
    message = Exception.message(error)

    if String.contains?(message, "unique_email") or
         String.contains?(message, "has already been taken") do
      "Email already registered"
    else
      "Could not create account. Please check the form and try again."
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
