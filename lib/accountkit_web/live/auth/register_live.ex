defmodule AccountkitWeb.Auth.RegisterLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.User
  alias Accountkit.RateLimit
  alias AccountkitWeb.Auth.{RegisterForm, RemoteIp}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create account")
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
end
