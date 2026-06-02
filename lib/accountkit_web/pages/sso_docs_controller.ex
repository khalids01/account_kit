defmodule AccountkitWeb.Pages.SsoDocsController do
  use AccountkitWeb, :controller

  def index(conn, _params) do
    render(conn, :index, page_title: "Application SSO")
  end
end
