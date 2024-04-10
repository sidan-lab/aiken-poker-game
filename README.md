# aiken-poker-game

## Specs

### Parameter - Game settings and contsraint

- `MaxPlayers`: Int 2 to Int 9
- `MinBuyIn`: AdaInt
- `BigBlind`: AdaInt
- `SmallBlind`: AdaInt
- `TableDealer`: Also fee collector address
- `IsTablePrivateOrOpen`: Bool

### Datum

- `ActiveGame`:
  - `ActivePlayersList`: [Player]
  - `MaxPlayers`: Int
  - `MinBuyInLovelace`: Int
  - `Player`: PlayerAddress && Balance

### Redeemer

- `JoinTable`: xxxxxxxxxxxxxxxxx
- `LeaveTable`: xxxxxxxxxxxxxxxxx
- `TopUpBalance`: xxxxxxxxxxxxxxxx

### User Action

1. A player creates a table - Each table is a validator script

   - Sets big/small blind
   - Sets Minimum buy-in
   - Sets maximum amount of players (minimum 2, up to 9)
   - Sets private/open table
     - If private, set which addresses are allowed to join

2. A player join the table - Redeemer `JoinTable`

   - Check whether table is private or not
     - If private, is player address authorized to join
     -
   - Check player address and balance
   - Check that table is not full
   - Check player deposit > Minimum buy-in
   - Deposit ADA in validator
   - Update Datum ActivePlayersList

3. A player tops up balance - Redeemer `TopUpBalance`

   - Check balance at player address
   - Check that top up > minimum buy-in
   - Build Tx:
     - Player signs Tx
     - Deposit ADA in validator
   - Update Datum ActivePlayersList
   - Update in-game balance

4. A player leaves the table - Redeemer `LeaveTable`
   - Check that player in active player list
   - Check player in-game balance
   - Match in-game balance with transaction validation
   - Build Tx:
     - Player signs Tx
     - Withdraw ADA
   - Update Datum ActivePlayersList

### Notable Points

- The rake will be capped at 5% of each pot
