defmodule AccountkitWeb.Auth.RegisterLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create account")
     |> assign_form(%{"name" => "", "email" => ""})}
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

          <.form for={@form} phx-submit="submit" class="space-y-5">
            <div>
              <label for={@form[:name].id} class="text-sm font-medium">Name</label>
              <input
                id={@form[:name].id}
                name={@form[:name].name}
                value={@form[:name].value}
                type="text"
                autocomplete="name"
                required
                class="input input-bordered mt-2 w-full"
                placeholder="Khalid"
              />
            </div>

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
  def handle_event("submit", %{"register" => params}, socket) do
    name = params["name"] |> to_string() |> String.trim()
    email = normalize_email(params["email"])
    socket = assign_form(socket, %{"name" => name, "email" => email})

    cond do
      name == "" ->
        {:noreply, put_flash(socket, :error, "Enter your name.")}

      email == "" ->
        {:noreply, put_flash(socket, :error, "Enter your email address.")}

      user_exists?(email) ->
        {:noreply,
         put_flash(socket, :error, "An account already exists for that email. Sign in instead.")}

      true ->
        case request_signup_magic_link(name, email) do
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

  defp assign_form(socket, params) do
    assign(socket, :form, to_form(params, as: :register))
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

  defp request_signup_magic_link(name, email) do
    User
    |> Ash.ActionInput.for_action(
      :request_signup_magic_link,
      %{name: name, email: email},
      authorize?: false
    )
    |> Ash.run_action()
  end

  defp normalize_email(email) do
    email
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end
end
