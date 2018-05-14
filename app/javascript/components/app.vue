<template>
  <div id="app">
    <h1 class="display-4">{{ message }}</h1>

    <card header="In Play">
      <ul>
        <li v-for="event in events"> {{ event.name }} </li>
      </ul>
    </card>
  </div>
</template>

<script>
import Card from './card.vue'

import gql from 'graphql-tag'

const EVENTS_QUERY = gql`{
  events {
    id
    name
  }
}
`

export default {
  data () {
    return {
      message: "Hello, World"
    }
  },
  components: {
    Card
  },
  apollo: {
    events: EVENTS_QUERY
  }
}
</script>
