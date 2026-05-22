defmodule Accountkit.Settings do
  use Ash.Domain, otp_app: :accountkit, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Accountkit.Settings.RateLimitPolicy
  end
end
