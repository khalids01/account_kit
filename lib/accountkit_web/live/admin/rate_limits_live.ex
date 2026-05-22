defmodule AccountkitWeb.Admin.RateLimitsLive do
  @moduledoc """
  Admin UI for editing rate limit policies stored in Postgres.
  """
  use AccountkitWeb, :live_view

  alias Accountkit.RateLimit
  alias Accountkit.Settings.RateLimitPolicy

  @impl true
  def mount(_params, _session, socket) do
    current_scope =
      case socket.assigns[:current_user] do
        %{__struct__: _} = user -> %{user: user}
        _ -> nil
      end

    {:ok,
     socket
     |> assign(:page_title, "Rate limits")
     |> assign(:current_scope, current_scope)
     |> load_policies()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl px-6 py-10">
        <div class="mb-8">
          <h1 class="text-2xl font-bold tracking-tight">Rate limits</h1>
          <p class="mt-2 text-sm text-base-content/70">
            Configure how many magic link requests are allowed per IP and per email. Changes apply
            within about 30 seconds on each running node.
          </p>
        </div>

        <div class="space-y-6">
          <div
            :for={row <- @policy_rows}
            id={"policy-#{row.policy.id}"}
            class="rounded-xl border border-base-300 bg-base-100 p-6 shadow-sm"
          >
            <.form for={row.form} phx-submit="save" phx-value-id={row.policy.id} class="space-y-4">
              <div>
                <h2 class="font-mono text-sm font-semibold text-primary">{row.policy.key}</h2>
                <p :if={row.policy.description} class="mt-1 text-sm text-base-content/70">
                  {row.policy.description}
                </p>
              </div>

              <div class="grid gap-4 sm:grid-cols-3">
                <div>
                  <label class="text-sm font-medium">Max attempts</label>
                  <input
                    type="number"
                    name={row.form[:limit].name}
                    value={row.form[:limit].value}
                    min="1"
                    required
                    class="input input-bordered mt-2 w-full"
                  />
                </div>

                <div>
                  <label class="text-sm font-medium">Window (seconds)</label>
                  <input
                    type="number"
                    name={row.form[:period_seconds].name}
                    value={row.form[:period_seconds].value}
                    min="1"
                    required
                    class="input input-bordered mt-2 w-full"
                  />
                </div>

                <div class="flex items-end">
                  <label class="flex cursor-pointer items-center gap-2">
                    <input
                      type="checkbox"
                      name={row.form[:enabled].name}
                      value="true"
                      checked={row.form[:enabled].value in [true, "true"]}
                      class="checkbox checkbox-primary"
                    />
                    <span class="text-sm font-medium">Enabled</span>
                  </label>
                </div>
              </div>

              <div>
                <label class="text-sm font-medium">Description</label>
                <input
                  type="text"
                  name={row.form[:description].name}
                  value={row.form[:description].value}
                  class="input input-bordered mt-2 w-full"
                />
              </div>

              <div class="flex justify-end">
                <button type="submit" class="btn btn-primary btn-sm">Save</button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("save", %{"id" => id, "policy" => params}, socket) do
    policy = Enum.find(socket.assigns.policies, &(&1.id == id))

    attrs = %{
      limit: parse_int(params["limit"]),
      period_seconds: parse_int(params["period_seconds"]),
      enabled: params["enabled"] in [true, "true", "on"],
      description: blank_to_nil(params["description"])
    }

    case Ash.update(policy, attrs, action: :update, authorize?: false) do
      {:ok, _policy} ->
        RateLimit.invalidate_policy_cache()

        {:noreply,
         socket
         |> put_flash(:info, "Saved #{policy.key}.")
         |> load_policies()}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not save rate limit policy.")}
    end
  end

  defp load_policies(socket) do
    policies =
      RateLimitPolicy
      |> Ash.Query.for_read(:list_all, %{})
      |> Ash.read!(authorize?: false)

    policy_rows =
      Enum.map(policies, fn policy ->
        %{
          policy: policy,
          form:
            to_form(
              %{
                "limit" => Integer.to_string(policy.limit),
                "period_seconds" => Integer.to_string(policy.period_seconds),
                "enabled" => policy.enabled,
                "description" => policy.description || ""
              },
              as: :policy
            )
        }
      end)

    assign(socket, policies: policies, policy_rows: policy_rows)
  end

  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(value) when is_integer(value), do: value

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
