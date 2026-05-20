defmodule AccountkitWeb.PageController do
  use AccountkitWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
