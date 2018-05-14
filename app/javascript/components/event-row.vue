<template>
  <div class="card mt-2">
    <div class="card-body">
      <h5 class="card-title">{{ event.description }}</h5>
      <p class="card-text">{{ fromNow(event.start_at) }}</p>
    </div>
  </div>
</template>

<script>
  import moment from 'moment'

  export default {
    props: ['event'],
    methods: {
      fromNow(timeString) {
        let time = moment(timeString)
        return time.fromNow()
      }
    }
  }
</script>
