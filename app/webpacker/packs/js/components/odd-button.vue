<template>
  <div class="col">
    <div class="btn btn-block btn-outline-primary">
      {{ displayName }}
    </div>
  </div>
</template>

<script>
  export default {
    props: ['odd'],
    computed: {
      displayName() {
        return `${this.odd.name} ${this.currentValue}`
      },
      currentValue() {
        return this.odd.odd_values[0].value
      }
    }
  }
</script>
