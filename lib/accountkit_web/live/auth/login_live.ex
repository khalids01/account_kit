defmodule AccountkitWeb.Auth.LoginLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.User
  alias Accountkit.RateLimit
  alias AccountkitWeb.Auth.{LoginForm, RemoteIp}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign_form(%{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.home flash={@flash} current_scope={nil}>
      <section class="mx-auto flex min-h-[calc(100vh-4rem)] max-w-md items-center px-6 py-16">
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
        {:noreply,
         put_flash(socket, :error, "Too many attempts. Please wait and try again.")}

      user_exists?(changeset) ->
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
         |> assign_form(
           Ecto.Changeset.add_error(changeset, :email, message)
         )}
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
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

  defp request_magic_link(%Ecto.Changeset{} = changeset) do
    email = Ecto.Changeset.get_field(changeset, :email)

    User
    |> Ash.ActionInput.for_action(:request_magic_link, %{email: email}, authorize?: false)
    |> Ash.run_action()
  end

  defp first_error(%Ecto.Changeset{errors: [{_field, {message, _opts}} | _]}), do: message
  defp first_error(_changeset), do: "Please fix the highlighted fields."
end
