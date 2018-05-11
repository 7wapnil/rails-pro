import Vue from 'vue/dist/vue.esm'
import TurbolinksAdapter from 'vue-turbolinks'

import App from '../app.vue'

Vue.use(TurbolinksAdapter)

document.addEventListener('turbolinks:load', () => {
  return new Vue({
    el: '#root',
    render: h => h(App)
  })
})
