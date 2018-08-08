Websocket emits list
============================

#### `oddChange`
Sent when new odd index received from odds feed provider  
**Data:**
* `id`:`String` - odd internal ID
* `value`:`Float` - new odd value received from provider

#### `updateMarket`
Sent when new market appears or at least one field of existing
market updated. 
**Data:**
* `id`:`String` - market internal ID
* `eventId`:`String` - market event internal ID
* `name`:`String` - market name
* `priority`:`Int` - market priority ( 0|1 )
