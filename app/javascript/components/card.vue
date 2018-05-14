<template>
  <div class="card">
    <h5 class="card-header">{{ header }}</h5>

    <div class="card-body">
      <slot></slot>
    </div>
  </div>
</template>

<script>
  export default {
    props: ['header']
  }
</script>
