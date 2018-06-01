<template>
  <div class="card mt-2">
    <div class="card-body">

      <div class="row">
        <div class="col">
          <h5 class="card-title">{{ event.description }}</h5>
        </div>
      </div>

      <div class="row align-items-end">
        <div class="col-lg-6">
          <div class="row">
            <div class="col-lg-12 col-sm-6">
              <p class="card-text font-weight-bold">{{ event.title_name }}</p>
            </div>

            <div class="col-lg-12 col-sm-6">
              <p class="card-text">{{ fromNow(event.start_at) }}</p>
            </div>
          </div>
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
