defmodule XrayWeb.BaseController do
  use XrayWeb, :controller

  def show(conn, _params) do
    redirect(conn, to: "/source")
  end
end
