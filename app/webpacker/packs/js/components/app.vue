<template>
  <div id="app">
    <card header="Events">
      <event-row v-for="(event, index) in events" :event="event"></event-row>
    </card>
  </div>
</template>

<script>
import Card from './card.vue'
import EventRow from './event-row.vue'

import gql from 'graphql-tag'

const EVENTS_QUERY = gql`{
  events {
    id
    name
    description
    discipline_name
    start_at
    end_at
    markets {
      id
      name
      priority
      odds {
        id
        name
        odd_values {
          id
          value
          created_at
        }
      }
    }
  }
}
`

export default {
  components: {
    Card,
    EventRow
  },
  apollo: {
    events: EVENTS_QUERY
  }
}
</script>
