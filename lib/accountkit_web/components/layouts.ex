defmodule AccountkitWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AccountkitWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates("layouts/*")

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  attr(:current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  )

  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <main>
        {render_slot(@inner_block)}
    </main>
    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :any, default: nil
  slot :inner_block, required: true
  def home(assigns) do
    ~H"""
    <main>
        <.home_header current_scope={@current_scope} />
        {render_slot(@inner_block)}
    </main>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div
      id={@id}
      aria-live="polite"
      class="pointer-events-none fixed inset-x-0 top-4 z-50 flex flex-col items-center gap-2 px-4"
    >
      <.flash
        kind={:info}
        flash={@flash}
        variant="toast"
        width="fit"
        rounded="extra_large"
        padding="small"
        border="extra_small"
        class="pointer-events-auto"
      />
      <.flash
        kind={:error}
        flash={@flash}
        variant="toast"
        width="fit"
        rounded="extra_large"
        padding="small"
        border="extra_small"
        class="pointer-events-auto"
      />

      <.flash
        id="client-error"
        kind={:error}
        variant="toast"
        width="fit"
        rounded="extra_large"
        padding="small"
        border="extra_small"
        class="pointer-events-auto"
        phx-disconnected={show_alert(".phx-client-error #client-error")}
        phx-connected={hide_alert("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ms-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        variant="toast"
        width="fit"
        rounded="extra_large"
        padding="small"
        border="extra_small"
        class="pointer-events-auto"
        phx-disconnected={show_alert(".phx-server-error #server-error")}
        phx-connected={hide_alert("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ms-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """

end
