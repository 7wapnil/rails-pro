Websocket emits list
============================

#### `oddChange`
Sent when new odd index received from odds feed provider  
**Data:**
* `id` - odd internal ID
* `value` - new odd value received from provider

#### `updateMarket`
Sent when new market appears or at least one field of existing
market updated. 
**Data:**
* `id` - market internal ID
* `eventId` - market event internal ID
* `name` - market name
* `priority` - market priority ( 0|1 )
