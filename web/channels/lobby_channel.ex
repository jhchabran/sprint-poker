defmodule PlanningPoker.LobbyChannel do
  use Phoenix.Channel

  alias PlanningPoker.Repo
  alias PlanningPoker.User
  alias PlanningPoker.Game
  alias PlanningPoker.Deck

  def join("lobby", message, socket) do
    send(self, {:after_join, message})
    {:ok, socket}
  end

  def handle_info({:after_join, message}, socket) do
    user = Repo.get!(User, socket.assigns.user_id)

    socket |> push "auth_token", %{auth_token: user.auth_token}
    socket |> push "user", %{user: user}
    socket |> push "decks", %{decks: Repo.all(Deck)}

    case message do
      %{"game_id" => game_id} ->
        game = Repo.get!(Game, game_id) |> Repo.preload([:owner])
        socket |> push "game", %{game: game}
      _ ->
    end

    {:noreply, socket}
  end

  def handle_in("change_user_name", message, socket) do
    user = %{Repo.get!(User, socket.assigns.user_id) | name: String.slice(message["name"], 0..254)} |> Repo.update!

    socket |> push "user", %{user: user}
    {:noreply, socket}
  end

  def handle_in("create_game", message, socket) do
    game = Repo.insert!(
      %Game{
        name: String.slice(message["name"], 0..254),
        owner_id: Repo.get!(User, socket.assigns.user_id).id,
        deck_id: Repo.get!(Deck, message["deck_id"]).id
      }
    ) |> Repo.preload([:owner])

    socket |> push "game", %{game: game}
    {:noreply, socket}
  end

  def handle_in("game_info", message, socket) do
    game = Repo.get!(Game, message["game_id"])

    socket |> push "game", %{game: game}

    {:noreply, socket}
  end

end
