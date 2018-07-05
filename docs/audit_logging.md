Audit logging
===================

Audit logging purpose is to store important user and customer actions in a history.
Logs are stored in MongoDB in the following format:
```json
{
  "created_at": "2018-07-05 9:15:11",
  "target": "Customer",
  "action": "update",
  "origin": {
    "kind": "user",
    "id": 1
  },
  "payload": {
    "foo": "bar",
    "hello": [1, 2, 3]
  }
}
```

To create a log record use `AuditService` service:
```ruby
AuditService.call(target: <tagret name>,
                  action: <action name>,
                  origin_kind: (:user|:customer|:system),
                  origin_id: <id>,
                  payload: {})
```

Where:
* `tagret` is a name of object event applied to
* `action` is a name of event triggered
* `origin_kind` is a type of user who triggered an action
* `origin_id` an ID of origin who triggered an action
* `payload` any additional data related to event
