defmodule AccountkitWeb.Components.UIComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()

  import AccountkitWeb.Components.Avatar, only: [avatar: 1]
  import AccountkitWeb.Components.Icon, only: [icon: 1]

  attr :class, :any, default: nil

  def logo(assigns) do
    ~H"""
    <.link navigate={~p"/"} class={["text-xl font-semibold tracking-tight", @class]}>
      AccountKit
    </.link>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  attr :id, :string, default: "user-menu"
  attr :current_scope, :any, default: nil

  def user_menu(assigns) do
    assigns =
      assign(assigns, :email, user_email(assigns.current_scope))

    ~H"""
    <details
      :if={@current_scope && @current_scope.user}
      id={@id}
      data-user-menu
      class="group relative"
    >
      <summary
        class="inline-flex size-10 cursor-pointer list-none items-center justify-center rounded-full border border-base-300 bg-base-100 shadow-sm transition hover:border-primary/60 hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-primary/40 [&::-webkit-details-marker]:hidden"
        aria-haspopup="menu"
        aria-controls={"#{@id}-content"}
      >
        <span class="sr-only">Open user menu</span>
        <.avatar size="small" rounded="full" color="primary" class="uppercase">
          {String.first(@email)}
        </.avatar>
      </summary>

      <div
        id={"#{@id}-content"}
        role="menu"
        class="absolute right-0 top-full z-50 mt-2 w-64 max-w-[calc(100vw-2rem)] origin-top-right overflow-hidden rounded-xl border border-base-300 bg-base-100 p-2 text-sm shadow-xl"
      >
        <div class="border-b border-base-300 px-3 py-2">
          <p class="text-xs font-medium uppercase tracking-wide text-base-content/50">Signed in as</p>
          <p class="mt-1 truncate font-medium text-base-content">{@email}</p>
        </div>

        <.link
          href="/profile"
          role="menuitem"
          class="mt-2 flex items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-user" class="size-4" />
          <span>Profile</span>
        </.link>

        <.link
          href="/dashboard"
          role="menuitem"
          class="flex items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-squares-2x2" class="size-4" />
          <span>Dashboard</span>
        </.link>

        <.link
          href={~p"/sign-out"}
          role="menuitem"
          class="mt-1 flex items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-arrow-right-on-rectangle" class="size-4" />
          <span>Sign out</span>
        </.link>
      </div>
    </details>
    """
  end

  defp user_email(%{user: %{email: email}}) when not is_nil(email), do: to_string(email)
  defp user_email(_current_scope), do: ""
end
