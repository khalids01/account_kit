defmodule AccountkitWeb.Features.ApplicationSso.Components do
  @moduledoc false

  use Phoenix.Component

  alias AccountkitWeb.Layouts

  attr :client, :map, default: nil
  attr :title, :string, required: true
  attr :error, :string, default: nil
  slot :inner_block, required: true

  def auth_shell(assigns) do
    ~H"""
    <Layouts.app flash={%{}} current_scope={nil}>
      <section class="mx-auto flex min-h-screen max-w-md items-center px-6 py-16">
        <div class="sso-auth-form w-full rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm [&_label]:!text-base-content [&_input:not([type=hidden])]:!border-base-300 [&_input:not([type=hidden])]:!bg-base-200 [&_input:not([type=hidden])]:!text-base-content [&_input:not([type=hidden])::placeholder]:!text-base-content/50">
          <div class="mb-8 text-center">
            <img
              :if={@client && @client.logoUrl}
              src={@client.logoUrl}
              alt={@client.name <> " logo"}
              class="mx-auto mb-4 max-h-16 max-w-36 object-contain"
            />
            <p :if={@client} class="text-sm font-medium text-base-content/60">
              {@client.name}
            </p>
            <h1 class="mt-3 text-2xl font-bold tracking-tight">{@title}</h1>
          </div>

          <div
            :if={@error}
            class="mb-5 rounded-xl border border-error/30 bg-error/10 px-4 py-3 text-sm text-error"
          >
            {@error}
          </div>

          {render_slot(@inner_block)}
        </div>
      </section>
    </Layouts.app>
    """
  end
end
