Websocket emits list
============================

#### `appStateUpdated`
Sent when status of application instance changed
**Data:**
* `status`:`String` - application status ( `inactive`|`active` )
* `live_connected`: `Bool` - is application live connected
* `pre_live_connected`: `Bool` - is application pre live connected
for detalis check `lib/application_state.rb`

#### `eventUpdated`
Sent on event state updated
**Data:**
* `id`:`String` - event internal ID
* `changes`:`Object` - event changed values
  * `state`:`String` - event state for details check `app/graphql/types/event_state_type.rb`

#### `marketsUpdated`
Sent when one or more markets updated
**Data:**
* `id`:`String` - market event internal ID
  * `data`: `Array` - list of updated markets
    * _anonymous_: `Object` - updated market
      * `id`:`String` - market internal ID
      * `priority`:`Int` - market priority ( 0|1 )
      * `status`:`String` - market status, for a list of possible statuses check 
      `app/services/odds_feed/radar/market_generator.rb`

#### `oddsUpdated`
Sent when one or more odds updated
**Data:**
* `id`:`String` - odd event internal ID
  * `data`: `Array` - list of updated odds
    * _anonymous_: `Object` - updated odd
      * `id`:`String` - odd internal ID
      * `value`:`Float` - odd value
      * `status`:`String` - odd status, for a list of statuses check
      `app/models/odd.rb`

#### `betSettled`
Sent when bets settled
**Data:**
* `id`:`String` - bet internal ID
* `customerId`:`Integer` - ID of customer bet made by
* `result`:`Boolean` - result of the bet
* `voidFactor`:`Float` - void factor of the bet
`app/models/bet.rb`

#### `betCancelled`
Sent when bets cancelled by odds provider  
**Data:**
* `id`:`String` - bet internal ID
* `customerId`:`Integer` - ID of customer bet made by
`app/models/bet.rb`

#### `betPlaced`
Report bet placement signal 
**Data:**
* `id`:`String` - bet internal ID
