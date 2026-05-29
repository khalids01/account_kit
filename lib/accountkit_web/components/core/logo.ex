defmodule AccountkitWeb.Components.Core.Logo do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()

  attr :class, :any, default: nil

  def logo(assigns) do
    ~H"""
    <.link navigate={~p"/"} class={["text-xl font-semibold tracking-tight", @class]}>
      AccountKit
    </.link>
    """
  end
end
