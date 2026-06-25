defmodule TunezWeb.Artists.FormLive do
  use TunezWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => artist_id}, _uri, socket) do
    artist = Tunez.Music.get_artist_by_id!(artist_id, actor: socket.assigns.current_user)

    form =
      Tunez.Music.form_to_update_artist(
        artist,
        actor: socket.assigns.current_user
      )
      |> AshPhoenix.Form.ensure_can_submit!()

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "Edit Artist")

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    form =
      Tunez.Music.form_to_create_artist(actor: socket.assigns.current_user)
      |> AshPhoenix.Form.ensure_can_submit!()

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "New Artist")

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        <.h1>{@page_title}</.h1>
      </.header>

      <.simple_form
        :let={form}
        id="artist_form"
        as={:form}
        for={@form}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={form[:name]} label="Name" />
        <.input field={form[:biography]} type="textarea" label="Biography" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"form" => form_data}, socket) do
    socket =
      socket
      |> update(:form, &AshPhoenix.Form.validate(&1, form_data))

    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
      {:ok, artist} ->
        socket =
          socket
          |> put_flash(:info, "Artist saved successfully")
          |> push_navigate(to: ~p"/artists/#{artist}")

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> put_flash(:error, "Failed to save artist: #{inspect(form.errors)}")
          |> assign(:form, form)

        {:noreply, socket}
    end
  end
end
