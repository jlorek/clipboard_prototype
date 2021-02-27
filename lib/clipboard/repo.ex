defmodule Clipboard.Repo do
  use Ecto.Repo,
    otp_app: :clipboard,
    adapter: Ecto.Adapters.Postgres
end
