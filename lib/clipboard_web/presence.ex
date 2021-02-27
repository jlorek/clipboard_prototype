defmodule ClipboardWeb.Presence do
  use Phoenix.Presence,
    otp_app: :clipboard,
    pubsub_server: Clipboard.PubSub
end
