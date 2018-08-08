Websocket emits list
============================

#### `updateEvent`
Sent when new event appears or at least one field of existing
event updated
**Data:**
* `id`:`String` - event internal ID
* `name`:`String` - event name

#### `updateMarket`
Sent when new market appears or at least one field of existing
market updated. 
**Data:**
* `id`:`String` - market internal ID
* `eventId`:`String` - market event internal ID
* `name`:`String` - market name
* `priority`:`Int` - market priority ( 0|1 )
* `status`:`String` - market status, for a list of possible statuses check 
`app/models/market.rb`

#### `oddChange`
Sent when new odd appears or at least one field of existing
odd updated.  
**Data:**
* `id`:`String` - odd internal ID
* `marketId`:`String` - odd market internal ID
* `eventId`:`String` - odd event internal ID
* `name`:`String` - odd name
* `value`:`Float` - odd value
* `status`:`String` - odd status, for a list of statuses check
`app/models/odd.rb`
