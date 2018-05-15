<template>
  <div class="card mt-2">
    <div class="card-body">
      <h5 class="card-title">{{ event.description }}</h5>

      <div class="row">
        <div class="col-lg-6">
          <p class="card-text">{{ fromNow(event.start_at) }}</p>
        </div>

        <div class="col-lg-6">
          <div class="row">
            <odd-button v-for="odd in primaryMarket.odds" :odd="odd"></odd-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import OddButton from './odd-button'

  import moment from 'moment'

  export default {
    props: ['event'],
    computed: {
      primaryMarket() {
        return this.event.markets.filter(market => market.priority === 1)[0]
      }
    },
    methods: {
      fromNow(timeString) {
        let time = moment(timeString)
        return time.fromNow()
      }
    },
    components: {
      OddButton
    }
  }
</script>
