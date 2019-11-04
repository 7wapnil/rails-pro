# Producers

Currently we are using **Live** and **Prematch** producers.


## Attributes

- **code** - code registered on BetRadar

- **state** - current state of producer

- **last_subscribed_at** - when was last successful `<alive>` message with `subscribed = 1` received

- **recovery_requested_at** - when last recovery was requested

- **recovery_snapshot_id** - last recovery id

- **recovery_node_id** - node id for which was requested last recovery (we're manipulating only with one `NODE_ID`)

- **last_disconnected_at** - when was last successful `<alive>` message with `subscribed = 1` received before `Radar::MissingHeartbeatWorker` detected that we didn't receive `<alive>` for longer than specified in `heartbeat limits` 


## Recovery limits

Request/time limits are calculated only for successful requests, they are not postponed after failed ones. 
Also limits are summed up for one BetRadar account (recovery requests with another NODE_ID are included in the total sum of requests).

**Max recovery length:** 60 hours.

- **24 hours - 60 hours:**

  **a)** 4 requests per 2 hours

  **b)** 2 requests per 30 minutes
  
  
- **30 minutes - 24 hours:**

  **a)** 10 requests per 1 hour

  **b)** 4 requests per 10 minutes

- **< 30 minutes:**

  **a)** 60 requests per 1 hour
  
  **b)** 20 requests per 10 minutes


## Producer heartbeat interval limits

**LIVE** - 15 seconds

**Prematch** - 5 minutes


## Recovery notes

Recovery is disabled by default on `development` environment. 
You can manually enable it using `RADAR_RECOVERY_ENABLED` env variable.
In case if recovery is called by system, but `disabled` we usually skip the recovery, instantly making our producer `HEALTHY`.

Our system requests recovery from the time picked **in the next order:**

1) if producer is currently recovering - takes last recovery requested time (`recovery_requested_at`)

2) if there is no disconnection time (`last_disconnected_at`):

    a) if there is last subscription message accepted time (`last_subscribed_at`) - takes it
  
    b) takes an approximate time when system went down (`10 minutes ago`)

3) if `last_disconnected_at` is older than max recovery length (`60 hours ago`) - takes max recovery length

4) takes `last_disconnected_at`


## Radar::AliveWorker

Using it we are informed about next action regarding respective message producer from BetRadar.

They send us `<alive>` message through Odds feed below `low_priority` queue and this worker processes it.

**We can:**

- keep connection subscribed on `subscribed = 1`

  **NB.** If our odds feed worker/listener was down for a while (more than specified in limits), or BetRadar send us messages very slow, we request a recovery

- request recovery for the period from last successful connection subscription on `subscribed = 0` and update subscription time


## Radar::MissingHeartbeatWorker

Is used for cases when everything is fine on our side, but there are issues or maintenance on BetRadar side.

Is called each `15 seconds` by default. Could be also defined using `MISSING_HEARTBEAT_CHECK_INTERVAL` env variable.

**We can:**

- register disconnection (using `last_disconnected_at` field) if previous `<alive>` message was not received in acceptable time range

- do nothing if:
 
  a) previous `<alive>` message was received in acceptable time range

  b) producer has already registered disconnection and currently is not HEALTHY


## Radar::SnapshotCompleteWorker

It is used to register completion of requested recovery.

They send us `<snapshot_complete>` message through Odds feed below `low_priority` queue and this worker processes it.

**We can:**

- ignore message if snapshot id is different from the last requested recovery

- complete recovery making our producer `HEALTHY`
