defmodule Accountkit.RateLimitTest do
  use Accountkit.DataCase, async: false

  alias Accountkit.RateLimit
  alias Accountkit.Settings.RateLimitPolicy

  setup do
    :ok = RateLimit.init_policy_cache()
    RateLimit.invalidate_policy_cache()
    :ok
  end

  test "denied?/2 returns false when under the limit" do
    refute RateLimit.denied?(:magic_link_sign_in, ip: "10.0.0.1", email: "test@example.com")
  end

  test "denied?/2 returns true when limit exceeded" do
    policy =
      RateLimitPolicy
      |> Ash.Query.for_read(:list_all, %{})
      |> Ash.read!(authorize?: false)
      |> Enum.find(&(&1.key == "magic_link_sign_in_ip"))

    Ash.update!(policy, %{limit: 1, period_seconds: 900}, authorize?: false)
    RateLimit.invalidate_policy_cache()

    refute RateLimit.denied?(:magic_link_sign_in, ip: "10.0.0.99", email: "limit@example.com")

    assert RateLimit.denied?(:magic_link_sign_in, ip: "10.0.0.99", email: "limit@example.com")
  end
end
