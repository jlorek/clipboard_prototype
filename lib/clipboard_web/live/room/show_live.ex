# lib/livechat_web/live/room/show_live.ex

defmodule ClipboardWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms.
  """

  use ClipboardWeb, :live_view

  alias Clipboard.Organizer
  alias Clipboard.ConnectedUser

  alias ClipboardWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def render(assigns) do
    ~L"""
    <h1><%= @room.title %></h1>
    <h3>Connected users:</h3>
    <ul>
    <%= for uuid <- @connected_users do %>
      <li><%= uuid %></li>
    <% end %>
    </ul>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = create_connected_user()
    # Clipboard.PubSub is defined in application.ex children
    Phoenix.PubSub.subscribe(Clipboard.PubSub, "room:" <> slug)
    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    case Organizer.get_room(slug) do
      nil ->
        {
          :ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: ClipboardWeb.Router.Helpers.room_new_path(socket, :new))
          # |> push_redirect(to: Routes.room_new_path(socket, :new))
        }

      room ->
        {:ok,
         socket
         |> assign(:room, room)
         |> assign(:user, user)
         |> assign(:slug, slug)
         |> assign(:connected_users, [])}
    end
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
     socket
     |> assign(:connected_users, list_present(socket))}
  end

  defp list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    # |> IO.inspect
    # %{
    #   "0b20d480-5c21-4141-ac1e-9c74caf06784" => %{
    #     metas: [%{phx_ref: "FmeeAgHwYNDfjhIE"}]
    #   },
    #   "6e667683-ab56-42a8-9760-e360ed4b0871" => %{
    #     metas: [%{phx_ref: "FmeeBf3zKmjfjhKC"}]
    #   }
    # }
    # Phoenix Presence provides nice metadata, but we don't need it.
    |> Enum.map(fn {k, _} -> k end)
  end

  defp create_connected_user do
    %ConnectedUser{
      uuid: UUID.uuid4()
    }
  end
end
