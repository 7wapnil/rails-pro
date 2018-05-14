<template>
  <div id="app">
    <h1 class="display-4">{{ message }}</h1>
    <ul>
      <li v-for="event in events"> {{ event.name }} </li>
    </ul>
  </div>
</template>

<script>
import gql from 'graphql-tag';

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
  apollo: {
    events: EVENTS_QUERY
  }
}
</script>
