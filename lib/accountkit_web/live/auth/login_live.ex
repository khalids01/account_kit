defmodule AccountkitWeb.Auth.LoginLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.User
  alias Accountkit.Auth.Email
  alias Accountkit.RateLimit
  alias AccountkitWeb.Auth.RemoteIp

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign_form(%{"email" => ""})}
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

          <.form for={@form} phx-submit="submit" class="space-y-5">
            <div>
              <label for={@form[:email].id} class="text-sm font-medium">Email</label>
              <input
                id={@form[:email].id}
                name={@form[:email].name}
                value={@form[:email].value}
                type="email"
                autocomplete="email"
                required
                class="input input-bordered mt-2 w-full"
                placeholder="you@example.com"
              />
            </div>

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
  def handle_event("submit", %{"login" => params}, socket) do
    email = Email.normalize(params["email"])
    ip = RemoteIp.from_socket(socket)

    socket = assign_form(socket, %{"email" => email})

    cond do
      email == "" ->
        {:noreply, put_flash(socket, :error, "Enter your email address.")}

      not Email.valid?(email) ->
        {:noreply, put_flash(socket, :error, "Enter a valid email address.")}

      RateLimit.denied?(:magic_link_sign_in, ip: ip, email: email) ->
        {:noreply,
         put_flash(socket, :error, "Too many attempts. Please wait and try again.")}

      user_exists?(email) ->
        case request_magic_link(email) do
          :ok ->
            {:noreply, put_flash(socket, :info, "Check your email for a magic sign-in link.")}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Could not send the magic link. Try again.")}
        end

      true ->
        {:noreply,
         put_flash(socket, :error, "No account exists for that email. Create an account first.")}
    end
  end

  defp assign_form(socket, params) do
    assign(socket, :form, to_form(params, as: :login))
  end

  defp user_exists?(email) do
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

  defp request_magic_link(email) do
    User
    |> Ash.ActionInput.for_action(:request_magic_link, %{email: email}, authorize?: false)
    |> Ash.run_action()
  end
end
