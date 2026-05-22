defmodule Accountkit.Accounts do
  use Ash.Domain, otp_app: :accountkit, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Accountkit.Accounts.Token
    resource Accountkit.Accounts.User
    resource Accountkit.Accounts.ApiKey
    resource Accountkit.Accounts.Organization
    resource Accountkit.Accounts.OrganizationMembership
    resource Accountkit.Accounts.PlatformRole
  end
end
