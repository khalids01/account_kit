defmodule AccountkitWeb.Components.UIComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()


  import AccountkitWeb.Components.Avatar, only: [avatar: 1]
  import AccountkitWeb.Components.Dropdown, only: [dropdown: 1, dropdown_content: 1]
  import AccountkitWeb.Components.Icon, only: [icon: 1]
  import AccountkitWeb.Components.Button, only: [button: 1]
  import AccountkitWeb.Components.List, only: [list: 1]

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
    ~H"""
    <.dropdown id={@id} :if={@current_scope && @current_scope.user} relative="relative" position="right">
      <:trigger>
        <.button color="primary" icon="hero-chevron-down" right_icon>
          <.avatar
            size="small"
            rounded="full"
            color="primary"
            text={String.first(@current_scope && @current_scope.user.email)}
          />
        </.button>
      </:trigger>
      <.dropdown_content>
        <.list size="small">
          <:item icon="hero-user">
            <.link navigate={~p"/users/profile"}>Profile</.link>
          </:item>
          <:item icon="hero-cog">
            <.link navigate={~p"/users/settings"}>Settings</.link>
          </:item>
          <:item icon="hero-logout">
            <.link navigate={~p"/auth/logout"}>Logout</.link>
          </:item>
        </.list>∏
        </.dropdown_content>
    </.dropdown>

    """
  end
end
