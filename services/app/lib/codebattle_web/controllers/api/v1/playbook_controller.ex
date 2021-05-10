defmodule CodebattleWeb.Api.V1.PlaybookController do
  use CodebattleWeb, :controller

  alias Codebattle.{Game, Repo, Task}
  alias Codebattle.GameProcess.{FsmHelpers, Play, Server}
  alias Codebattle.Bot.Playbook
  import Ecto.Query, warn: false

  def show(conn, %{"id" => game_id}) do
    query =
      from(
        p in Playbook,
        where: p.game_id == ^game_id,
        limit: 1
      )

    case Play.get_fsm(game_id) do
      {:ok, fsm} ->
        {:ok, records} = Server.get_playbook(game_id)

        winner = FsmHelpers.get_winner(fsm)
        winner_id = if is_nil(winner), do: nil, else: winner.id
        winner_lang = if is_nil(winner), do: nil, else: winner.editor_lang

        json(conn, %{
          players: FsmHelpers.get_players(fsm),
          records: Enum.reverse(records),
          task: FsmHelpers.get_task(fsm),
          type: FsmHelpers.get_type(fsm),
          tournament_id: FsmHelpers.get_tournament_id(fsm),
          winner_id: winner_id,
          winner_lang: winner_lang
        })

      _ ->
        playbook = Repo.one(query)
        game = Repo.get(Game, game_id)
        task = Repo.get(Task, playbook.task_id)

        json(conn, %{
          players: playbook.data.players,
          records: playbook.data.records,
          task: task,
          type: game.type,
          tournament_id: game.tournament_id,
          winner_id: playbook.winner_id,
          winner_lang: playbook.winner_lang
        })
    end
  end
end
