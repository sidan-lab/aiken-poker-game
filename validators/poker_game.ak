use aiken/transaction.{ScriptContext, Spend}
use aiken/transaction/credential.{Address}

type GameDatum {
  ActiveGame {
    max_players: Int,
    min_buy_in_lovelace: Int,
    current_players: List<Address>,
  }
}

type GameRedeemer {
  JoinTable { new_player: Address }
  LeaveTable { player_to_remove: Address }
}

validator(fee_collector: Address) {
  fn poker_game(
    datum: GameDatum,
    redeemer: GameRedeemer,
    context: ScriptContext,
  ) {
    let ScriptContext { purpose, transaction } = context
    expect Spend(_) = purpose
    when redeemer is {
      JoinTable { new_player } -> {
        let is_min_buy_in_met = False
        let is_room_having_vacancy = False
        let is_player_already_at_table = False
        let is_datum_updated = False

        is_min_buy_in_met && is_room_having_vacancy && is_player_already_at_table
      }
      LeaveTable { player_to_remove } -> {
        let is_player_removed = False
        let is_money_returned = False

        is_player_removed && is_money_returned
      }
    }
  }
}
