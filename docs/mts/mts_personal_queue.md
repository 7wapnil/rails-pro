[Pull request](https://github.com/arcanebet/backend/pull/750)  introduce rake task which will help to setup *queue* per dev for **ticket validation** and **ticket cancellation**.
For example:
```
rake mts:ticket_cancellation:create MTS_MQ_QUEUE_REPLY='[MTS_MQ_USER]-Reply-dev-oleksii-test'
```
*Note: support recommend to have queue names like this: MTS_MQ_USER-[EXCHANGE_NAME]-[preferably your name]. This is done to avoid name collisions.*

This will create *queue* with name *MTS_MQ_QUEUE_REPLY*, then **bind** *exchange* to this query. Binding is very important! In case *queue* is not binded, **you will not receive messages**. You could also provide *routing_key*, or use default.

### You should not run this command too often! This will pollute rabbitMQ with too many queues.
### In case someone decide to have some experiments -> you should not produce **exchanges** that are not supported. Read do first!
