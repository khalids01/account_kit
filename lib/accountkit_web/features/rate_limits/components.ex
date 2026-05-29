defmodule AccountkitWeb.Features.RateLimits.Components do
  use Phoenix.Component

  attr :policy_rows, :list, required: true

  def policy_list(assigns) do
    ~H"""
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
    """
  end
end
