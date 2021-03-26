# lib/littlechat_web/live/room/new_live.ex

defmodule ClipboardWeb.Room.NewLive do
  use ClipboardWeb, :live_view

  alias Clipboard.Repo
  alias Clipboard.Organizer.Room

  # render/1 implements a LiveView callback with the given assigns (variables containing session data) and expects a ~L sigil (Live EEx). I prefer my LEEx templates inline, but you’re welcome to create a file lib/littlechat_web/live/room/new_live.html.leex and get rid of this function if you prefer to keep your templates separate.
  @impl true
  def render(assigns) do
    # import { hello } from "/js/clipboard.js"
    ~L"""
    <script type="module">
    import { hello } from "/js/clipboard.js"
    hello("world")
    </script>
    <script>
    console.log("new_live.ex")
    </script>
    <h1>Create a New Room</h1>
    <div>
      <%= form_for @changeset, "#", [phx_change: "validate", phx_submit: "save"], fn f -> %>
        <%= text_input f, :title, placeholder: "Title" %>
        <%= error_tag f, :title %>
        <%= text_input f, :slug, placeholder: "room-slug" %>
        <%= error_tag f, :slug %>
        <%= submit "Save" %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> put_changeset()
    }
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    {:noreply,
      socket
      |> put_changeset(room_params)
    }
  end

  def handle_event("save", _, %{assigns: %{changeset: changeset}} = socket) do
    case Repo.insert(changeset) do
      {:ok, room} ->
        {:noreply,
          socket
          |> push_redirect(to: ClipboardWeb.Router.Helpers.room_show_path(socket, :show, room.slug))
          # |> push_redirect(to: Routes.room_show_path(socket, :show, room.slug))
        }
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Could not save the room.")
        }
    end
  end

  defp put_changeset(socket, params \\ %{}) do
    IO.inspect(params)
    socket
    |> assign(:changeset, Room.changeset(%Room{}, params))
  end
end
