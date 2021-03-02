defmodule ClipboardWeb.Playground.ThermostatLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use ClipboardWeb, :live_view

  def render(assigns) do
    ~L"""
    <div id="thermo-live" phx-hook="whatever">
    <div>Current temperature: <%= @temperature %></div>
    <div>Current time: <%= @time %></div>
    <input id="thermo-input" phx-hook="messenger" type="text"> </input>
    </div>
    """
  end

  # def mount(_params, %{"current_user_id" => user_id}, socket) do
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)
    # temperature = Thermostat.get_user_reading(user_id)
    temperature = 18.6

    {:ok,
     socket
     |> assign(:temperature, temperature)
     |> assign(:time, DateTime.to_string(DateTime.utc_now()))}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)
    {:noreply, assign(socket, :time, DateTime.to_string(DateTime.utc_now()))}
  end

  def handle_event("paste", _params = %{"pasteData" => data}, socket) do
    data |> IO.inspect(label: "Received Data")
    {:noreply, socket}
  end
end
