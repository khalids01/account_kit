defmodule Accountkit.RateLimit do
  @moduledoc """
  Enforces configurable rate limits using Hammer (ETS) and `RateLimitPolicy` rows.
  """
  alias Accountkit.Settings.RateLimitPolicy

  @policy_cache_table :accountkit_rate_limit_policies
  @policy_cache_key :all_policies
  @policy_cache_ttl_ms 30_000

  @action_policy_keys %{
    magic_link_sign_in: ["magic_link_sign_in_ip", "magic_link_sign_in_email"],
    magic_link_sign_up: ["magic_link_sign_up_ip", "magic_link_sign_up_email"]
  }

  @doc """
  Returns true when any applicable policy denies the request.
  """
  def denied?(action, opts) when is_atom(action) and is_list(opts) do
    case check(action, opts) do
      :ok -> false
      {:error, :rate_limited} -> true
    end
  end

  @doc """
  Checks all enabled policies for the action. Returns `:ok` or `{:error, :rate_limited}`.
  """
  def check(action, opts) when is_atom(action) and is_list(opts) do
    ip = Keyword.get(opts, :ip, "unknown")
    email = Keyword.get(opts, :email)

    action
    |> policy_keys()
    |> Enum.reduce_while(:ok, fn policy_key, _acc ->
      case fetch_policy(policy_key) do
        nil ->
          {:cont, :ok}

        %{enabled: false} ->
          {:cont, :ok}

        policy ->
          case check_policy(policy, policy_key, ip, email) do
            :ok -> {:cont, :ok}
            {:error, :rate_limited} = error -> {:halt, error}
          end
      end
    end)
  end

  defp policy_keys(action) do
    Map.get(@action_policy_keys, action, [])
  end

  defp fetch_policy(key) do
    policies_by_key()
    |> Map.get(key)
  end

  defp policies_by_key do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@policy_cache_table, @policy_cache_key) do
      [{@policy_cache_key, policies, expires_at}] when expires_at > now ->
        policies

      _ ->
        load_policies(now)
    end
  end

  defp load_policies(now) do
    policies =
      RateLimitPolicy
      |> Ash.Query.for_read(:list_all, %{})
      |> Ash.read!(authorize?: false)
      |> Map.new(&{&1.key, &1})

    expires_at = now + @policy_cache_ttl_ms
    :ets.insert(@policy_cache_table, {@policy_cache_key, policies, expires_at})
    policies
  end

  defp check_policy(%{limit: limit, period_seconds: period_seconds}, policy_key, ip, email) do
    identifier = identifier_for(policy_key, ip, email)
    scale_ms = period_seconds * 1_000
    bucket_id = "#{policy_key}:#{identifier}"

    case Hammer.check_rate(bucket_id, scale_ms, limit) do
      {:allow, _count} -> :ok
      {:deny, _limit} -> {:error, :rate_limited}
    end
  end

  defp identifier_for(key, ip, email) do
    cond do
      String.ends_with?(key, "_ip") -> ip
      String.ends_with?(key, "_email") and is_binary(email) and email != "" -> email
      true -> "unknown"
    end
  end

  @doc false
  def init_policy_cache do
    if :ets.whereis(@policy_cache_table) == :undefined do
      :ets.new(@policy_cache_table, [:named_table, :set, :public, read_concurrency: true])
    end

    :ok
  end

  @doc """
  Clears cached policies so admin edits take effect immediately.
  """
  def invalidate_policy_cache do
    if :ets.whereis(@policy_cache_table) != :undefined do
      :ets.delete_all_objects(@policy_cache_table)
    end

    :ok
  end
end
