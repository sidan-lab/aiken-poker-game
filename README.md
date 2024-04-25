# aiken-poker-game

## Specs

### Parameter - Game settings and contsraint

- `TableDealer`: PubKeyHash
  The only pubKeyHash able to sign leave table transactions.

### Datum

- `ActiveOpenGame`:

  - `ActivePlayersList`: [Address]
  - `TotalDeposit`: Int
  - `MaxPlayers`: Int
  - `MinBuyInLovelace`: Int

- `ActivePrivateGame`:
  - `ActivePlayersList`: [Address]
  - `TotalDeposit`: Int
  - `MaxPlayers`: Int
  - `MinBuyInLovelace`: Int
  - `AuthorizedPlayers`: [PubKeyHash]

### Redeemer

- `JoinTable`:

  - Address
  - DepositAmount

- `LeaveTable`:

  - Address
  - WithdrawalAmount

- `TopUpBalance`:
  - Address
  - DepositAmount

### User Action

1. A player creates a table - Each table is a validator script

   - Note:
     - Sets big/small blind
     - Sets Minimum buy-in
     - Sets maximum amount of players (minimum 2, up to 9)
     - Sets private/open table
       - If private, set which addresses are allowed to join

2. A player join the table - Redeemer `JoinTable`

   - Script Context, looking at Transaction:

     - Only 1 input UTXO from current script address
     - Only 1 output to current script address
     - Update Datum ActivePlayersList and TotalDeposit
     - Check input values and output matches with supposed change in TotalDeposit.

   - Check whether table is private or not
     - If private, check if member in `AuthorizedPlayers` in datum
   - Check that table is not full
   - Check player deposit > Minimum buy-in

   - Note:
     - Check player address and balance
     - Build Tx:
     - Player signs Tx
     - Deposit ADA in validator

3. A player tops up balance - Redeemer `TopUpBalance`

   - Check that top up > minimum buy-in
   - Build Tx:
     - Player signs Tx
     - Deposit ADA in validator
   - Update Datum ActivePlayersList and TotalDeposit
   - Update in-game balance

   - Note: Check balance at player address

4. A player leaves the table - Redeemer `LeaveTable`
   - Check that player in activePlayer list
   - Check player in-game balance
   - Match in-game balance with transaction validation
   - Update Datum ActivePlayersList and TotalDeposit
   - Build Tx:
     - Admin signs Tx
     - Withdraw ADA

Note: Player does not need to sign `LeaveTable` Tx. This way, we can control the flow and kick inactive players out

### Notable Points

- The rake will be capped at 5% of each pot
