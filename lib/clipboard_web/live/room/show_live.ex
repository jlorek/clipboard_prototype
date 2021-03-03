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
    <div id="<%= UUID.uuid4() %>" phx-hook="messenger" />
    <h1><%= @room.title %></h1>
    <h3>Connected users:</h3>
    <ul>
    <%= for uuid <- @connected_users do %>
      <li><%= uuid %></li>
    <% end %>
    </ul>

    <h3>Paste data</h3>
    <div>Content: <%= @mime_type %></div>
    <%= cond do %>
    <% String.starts_with?(@mime_type, "text/") -> %>
      <pre style="white-space: pre-wrap;"><%= @data %></pre>
    <% String.starts_with?(@mime_type, "image/") -> %>
      <img src="<%= @data %>"></img>
    <% true -> %>
      <div>Unprocessable</div>
    <% end %>

    <%= form_for :input, "#", [phx_change: "validate", phx_submit: "save"],fn f -> %>
    <%= text_input f, :title, placeholder: "Title" %>
    <%= error_tag f, :title %>
    <%= submit "Save" %>
    <% end %>

    <button id="read-html">Paste HTML below</button>
    <div id="html-output"></div>


    <script>
    window.addEventListener("paste", async (event) => {
      event.preventDefault();

      if(event.clipboardData == false){
        return
      }

      // chrome text order: plain, html
      // safari text order: html, plain
      // chrome file order: plain, file
      // safari file order: file
      var items = event.clipboardData.items

      var arrayItems = [];
      for (let item of items) {
        arrayItems.push(item);
      }
      arrayItems.sort()

      for (let item of items) {
        console.log(item);
        // must be saved for Chrome,
        // otherwise item.type is empty
        // after waiting for async result
        const mimeType = item.type;
        let data = undefined;

        // text/plain, text/html, text/uri-list
        if (item.kind === "string") {
          data = await readText(item);
        }

        // image/png
        if (item.kind === "file") {
          data = await readFile(item);
        }

        if (data) {
          window.socketMessenger.pasteClipboard(mimeType, data);
          return;
        }
      }
    }, false);

    async function readText(dataTransferItem) {
      var text = await toString(dataTransferItem);
      console.log("Got text from paste", text);
      return text;
    }

    async function readFile(dataTransferItem) {
      const file = dataTransferItem.getAsFile();
      // file.name/size/type
      console.log("Got file from paste", file);
      var base64 = await toBase64(file);
      console.log("File content", base64);
      return base64;
    }

    const toBase64 = file => new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result);
      reader.onerror = error => reject(error);
    });

    const toString = dataTransferItem => new Promise((resolve, reject) => {
      dataTransferItem.getAsString((result) => {
        resolve(result);
      });
    });

    //document.getElementById("read-html").addEventListener("click", onPaste);
    //document.getElementsByTagName("body")[0].addEventListener("paste", onPaste)
    async function onPaste(pasteEvent) {
      // simple paste data extraction
      // let paste = (pasteEvent.clipboardData || window.clipboardData).getData('text');
      // console.log("Got something from a paste event: " + paste)

      const acceptedTypes = ["text/plain", "text/html"]
      const items = await navigator.clipboard.read();
      for (let item of items) {
        for (let acceptedType of acceptedTypes) {
          if (!item.types.includes(acceptedType)) {
            continue
          }
          const reader = new FileReader;
          reader.addEventListener("load", loadEvent => {
            const content = reader.result;
            document.getElementById("html-output").innerHTML = reader.result;
            window.socketMessenger.sendClipboardData(content)
          });
          const typeData = await item.getType(acceptedType)
          reader.readAsText(typeData)
          return
        }
      }
      console.log("Got paste data, but could not extract text.", items)
    }

    </script>
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
         |> assign(:mime_type, "text/plain")
         |> assign(:data, "nothing yet...")
         |> assign(:connected_users, [])}
    end
  end

  @impl true
  def handle_event("validate", params, socket) do
    params |> IO.inspect(label: "validate_params")
    {:noreply, socket}
  end

  def handle_event("save", params, socket) do
    params |> IO.inspect(label: "save_params")
    {:noreply, socket}
  end

  @impl true
  def handle_event("paste", _params = %{"pasteData" => data}, socket) do
    data |> IO.inspect(label: "Received paste data")
    Phoenix.PubSub.broadcast(Clipboard.PubSub, "room:" <> socket.assigns.slug, %{paste_data: data})
    {:noreply, socket}
  end

  def handle_event("paste", _params = %{"mimeType" => mime_type, "data" => data}, socket) do
    data |> IO.inspect(label: "Received paste data")
    Phoenix.PubSub.broadcast(
      Clipboard.PubSub,
      "room:" <> socket.assigns.slug,
      %{mime_type: mime_type, data: data})
    {:noreply, socket}
  end

  def handle_info(params = %{paste_data: data}, socket) do
    IO.inspect(params, label: "Received paste broadcast")
    socket = assign(socket, :data, data)
    {:noreply, socket}
  end

  def handle_info(params = %{mime_type: mime_type, data: data}, socket) do
    IO.inspect(params, label: "Received paste broadcast")
    socket = socket
      |> assign(:mime_type, mime_type)
      |> assign(:data, data)
    {:noreply, socket}
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
