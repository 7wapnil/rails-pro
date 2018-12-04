Websocket emits list
============================

#### `appStateUpdated`
Sent when status of application instance changed
**Data:**
* `status`:`Integer` - application status ( 0|1 ), for
detalis check `lib/application_state.rb`

#### `eventCreated`
Sent when new event appears
**Data:**
* `id`:`String` - event internal ID

#### `eventUpdated`
Sent when at least one field of existing
event updated
**Data:**
* `id`:`String` - event internal ID
* `changes`:`Object` - event changed values
  * `name`:`String` - event name
  * `event_status`:`EventStatus` - event status details, for `EventStatus`
  details check `app/graphql/types/event_status_type.rb` and
  `app/graphql/types/period_score_type.rb`

#### `marketCreated`
Sent when new market appears
**Data:**
* `id`:`String` - market internal ID
* `eventId`:`String` - market event internal ID

#### `marketUpdated`
Sent when at least one field of existing
market updated.
**Data:**
* `id`:`String` - market internal ID
* `eventId`:`String` - market event internal ID
* `changes`:`Object` - market changed values
  * `name`:`String` - market name
  * `priority`:`Int` - market priority ( 0|1 )
  * `status`:`String` - market status, for a list of possible statuses check 
  `app/models/market.rb`

#### `marketsUpdated`
**Need more information about triggering process**
**Data:**
* `id`:`String` - market event internal ID
  * `data`: `Array` - list of updated markets
    * _anonymous_: `Object` - updated market
      * `id`:`String` - market internal ID
      * `priority`:`Int` - market priority ( 0|1 )
      * `status`:`String` - market status, for a list of possible statuses check 
      `app/services/odds_feed/radar/market_generator.rb`

#### `oddCreated`
Sent when new odd appears.  
**Data:**
* `id`:`String` - odd internal ID
* `marketId`:`String` - odd market internal ID
* `eventId`:`String` - odd event internal ID
`app/models/odd.rb`

#### `oddUpdated`
Sent when at least one field of existing odd updated.  
**Data:**
* `id`:`String` - odd internal ID
* `marketId`:`String` - odd market internal ID
* `eventId`:`String` - odd event internal ID
* `changes`:`Object` - odd's changed values
  * `name`:`String` - odd name
  * `value`:`Float` - odd value
  * `status`:`String` - odd status, for a list of statuses check
  `app/models/odd.rb`

#### `oddsUpdated`
**Need more information about triggering process**
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
