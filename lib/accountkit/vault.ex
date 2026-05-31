defmodule Accountkit.Vault do
  use Cloak.Vault, otp_app: :accountkit

  @impl GenServer
  def init(config) do
    config =
      case System.get_env("ACCOUNTKIT_CLOAK_KEY") do
        nil ->
          config

        key ->
          Keyword.put(config, :ciphers,
            default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Base.decode64!(key)}
          )
      end

    {:ok, config}
  end
end
