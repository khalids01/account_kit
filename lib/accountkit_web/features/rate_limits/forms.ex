defmodule AccountkitWeb.Features.RateLimits.Forms do
  import Phoenix.Component, only: [to_form: 2]

  alias Accountkit.Settings.RateLimitPolicy

  def list_policies do
    RateLimitPolicy
    |> Ash.Query.for_read(:list_all, %{})
    |> Ash.read!(authorize?: false)
  end

  def policy_rows(policies) do
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
  end

  def attrs_from_params(params) do
    %{
      limit: parse_int(params["limit"]),
      period_seconds: parse_int(params["period_seconds"]),
      enabled: params["enabled"] in [true, "true", "on"],
      description: blank_to_nil(params["description"])
    }
  end

  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(value) when is_integer(value), do: value

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
