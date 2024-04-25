use aiken/list
use aiken/transaction.{InlineDatum, ScriptContext, Spend, Transaction, find_input}
use aiken/transaction/credential.{Address}
use sidan_utils/inputs.{inputs_at}
use sidan_utils/outputs.{outputs_at}
use sidan_utils/value.{value_geq} as sidan_value
use aiken/transaction/value.{Value, add, lovelace_of}

type GameDatum {
  ActiveOpenGame {
    active_players_list: List<Address>,
    total_deposit: Int,
    max_players: Int,
    min_buy_in_lovelace: Int,
  }
  
  ActivePrivateGame {
    active_players_list: List<Address>,
    authorized_players_list: List<Address>,
    total_deposit: Int,
    max_players: Int,
    min_buy_in_lovelace: Int,
  }
}

type GameRedeemer {
  JoinTable { new_player: Address }
  TopUp {new_balance: Int}
  LeaveTable { player_to_remove: Address }
}

validator(fee_collector: Address) {
  fn poker_game(
    datum: GameDatum,
    redeemer: GameRedeemer,
    context: ScriptContext,
  ) {
    let ScriptContext { purpose, transaction } = context
    let Transaction {inputs, reference_inputs, outputs, fee, redeemers, datums, ..} = transaction
    expect Spend(utxo) = purpose
    when redeemer is {

      JoinTable { new_player } -> {
        expect Some(own_input) = find_input(inputs, utxo)
        let own_address = own_input.output.address
        when (inputs_at(inputs, own_address), outputs_at(outputs, own_address)) is {
          ([only_input_from_script], [only_output_to_script]) -> {
            let input_value = only_input_from_script.output.value
            let output_value = only_output_to_script.value

            when datum is {
              ActiveOpenGame {active_players_list, total_deposit, max_players, min_buy_in_lovelace} -> {

                expect InlineDatum(output_inline_datum) = only_output_to_script.datum
                expect ActiveOpenGame { .. } : GameDatum  = output_inline_datum
                expect parsed_output_datum : GameDatum = output_inline_datum
                // let lovelace_input_value : Int = lovelace_of(input_value)
                let lovelace_output_value : Int = lovelace_of(output_value)
                // All conditions that must be satisfied
                and {
                  does_table_have_seats(active_players_list, max_players),
                  is_player_already_at_table(active_players_list, new_player),
                  is_min_buy_in_met(min_buy_in_lovelace, input_value, output_value),
                  is_datum_updated_open(datum, parsed_output_datum, lovelace_output_value, new_player)
                }
              }

              ActivePrivateGame{active_players_list, authorized_players_list, total_deposit, max_players, min_buy_in_lovelace} -> {
                expect InlineDatum(output_inline_datum) = only_output_to_script.datum
                expect ActivePrivateGame { .. } : GameDatum  = output_inline_datum
                expect parsed_output_datum : GameDatum = output_inline_datum
                // let lovelace_input_value : Int = lovelace_of(input_value)
                let lovelace_output_value : Int = lovelace_of(output_value)
                
                // All conditions that must be satisfied
                and {
                  is_player_authorized(authorized_players_list, new_player),
                  does_table_have_seats(active_players_list, max_players),
                  is_player_already_at_table(active_players_list, new_player),
                  is_min_buy_in_met(min_buy_in_lovelace, input_value, output_value),
                  is_datum_updated_private(datum, parsed_output_datum, lovelace_output_value, new_player)
                }
              } 
            }
          }
          _ -> False
        }
      }
    
  

      TopUp { new_balance } -> {
        expect Some(own_input) = find_input(inputs, utxo)
        let own_address = own_input.output.address
        when (inputs_at(inputs, own_address), outputs_at(outputs, own_address)) is {
          ([input], [output]) -> {
            let input_value = input.output.value
            let output_value = output.value

            when datum is {
              ActiveOpenGame {min_buy_in_lovelace, ..} -> {

                expect InlineDatum(output_inline_datum) = output.datum
                expect ActiveOpenGame { .. } : GameDatum  = output_inline_datum
                expect parsed_output_datum : GameDatum = output_inline_datum
                // let lovelace_input_value : Int = lovelace_of(input_value)
                let lovelace_output_value : Int = lovelace_of(output_value)
                // All conditions that must be satisfied
                and {
                  is_min_buy_in_met(min_buy_in_lovelace, input_value, output_value),
                  is_datum_updated_topup_open(datum, parsed_output_datum, lovelace_output_value, new_balance)
                }
              }

              ActivePrivateGame{min_buy_in_lovelace, ..} -> {
                expect InlineDatum(output_inline_datum) = output.datum
                expect ActivePrivateGame { .. } : GameDatum  = output_inline_datum
                expect parsed_output_datum : GameDatum = output_inline_datum
                // let lovelace_input_value : Int = lovelace_of(input_value)
                let lovelace_output_value : Int = lovelace_of(output_value)
                
                // All conditions that must be satisfied
                and {
                  is_min_buy_in_met(min_buy_in_lovelace, input_value, output_value),
                  is_datum_updated_topup_private(datum, parsed_output_datum, lovelace_output_value, new_balance)
                }
              } 
            }
          }
          _ -> False
        }
      }


      LeaveTable { player_to_remove } -> {
        // let is_player_removed = False
        // let is_money_returned = False

        // is_player_removed && is_money_returned
        False
      }
    }
  }
}




///// Supporting functions for JoinTable redeemer

// Static checking

fn is_player_authorized(authorized_players_list, new_player) -> Bool {
  list.has(authorized_players_list, new_player)
}

fn is_player_already_at_table(active_players_list, new_player) -> Bool {
  list.has(active_players_list, new_player)
}

fn does_table_have_seats(active_players_list, max_players) -> Bool {
  list.length(active_players_list) < max_players
}


// Dynamic checking
fn is_min_buy_in_met(min_buy_in_lovelace : Int, input_value: Value, output_value: Value) -> Bool { 
  let is_buy_in_provided = value_geq(output_value |> add("", "", min_buy_in_lovelace), input_value)  
    is_buy_in_provided
    }

fn is_datum_updated_open(input_datum: GameDatum, output_datum: GameDatum, output_value: Int, new_player: Address) -> Bool {
  // We are only updating the active_players_list and total_deposit
  expect ActiveOpenGame {active_players_list: input_active_players_list, .. } : GameDatum = input_datum
  expect ActiveOpenGame {active_players_list: output_active_players_list, total_deposit: output_total_deposit, ..} : GameDatum = output_datum
  

  let is_new_player_added = list.length(input_active_players_list) + 1 == list.length(output_active_players_list) 
      && list.has(output_active_players_list, new_player)

  let is_total_deposit_updated = output_total_deposit == output_value 
    // && output_total_deposit - input_total_deposit == output_value - input_value 

  is_new_player_added && is_total_deposit_updated
}

fn is_datum_updated_private(input_datum: GameDatum, output_datum: GameDatum, output_value: Int, new_player: Address) -> Bool {
  // We are only updating the active_players_list and total_deposit
  expect ActivePrivateGame {active_players_list: input_active_players_list, ..} : GameDatum = input_datum
  expect ActivePrivateGame {active_players_list: output_active_players_list, total_deposit: output_total_deposit, ..} : GameDatum = output_datum
  

  let is_new_player_added = list.length(input_active_players_list) + 1 == list.length(output_active_players_list) 
      && list.has(output_active_players_list, new_player)

  let is_total_deposit_updated = output_total_deposit == output_value 
    // && output_total_deposit - input_total_deposit == output_value - input_value 

  is_new_player_added && is_total_deposit_updated
}


///// Supporting functions for TopUp redeemer
fn is_datum_updated_topup_open(input_datum: GameDatum, output_datum: GameDatum, output_value: Int, new_balance: Int) {
  expect ActiveOpenGame { total_deposit: input_total_deposit, ..} : GameDatum = input_datum
  expect ActiveOpenGame { total_deposit: output_total_deposit, ..} : GameDatum = output_datum

  let is_total_deposit_updated = output_total_deposit == output_value 
    // && output_total_deposit - input_total_deposit == output_value - input_value
    // && new_balance - output_value == input_value

    is_total_deposit_updated
}

fn is_datum_updated_topup_private(input_datum: GameDatum, output_datum: GameDatum, output_value: Int, new_balance: Int) {
  expect ActivePrivateGame {total_deposit: input_total_deposit, ..} : GameDatum = input_datum
  expect ActivePrivateGame {total_deposit: output_total_deposit, ..} : GameDatum = output_datum

    let is_total_deposit_updated = output_total_deposit == output_value 
    // && output_total_deposit - input_total_deposit == output_value - input_value
    // && new_balance - output_value == input_value

    is_total_deposit_updated
}


///// Supporting functions for LeaveTable redeemer
