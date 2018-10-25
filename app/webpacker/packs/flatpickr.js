import 'flatpickr/dist/flatpickr.css'
import 'flatpickr/dist/themes/airbnb.css'

import flatpickr from 'flatpickr'

const dateFormat = 'j F Y'

document.addEventListener('turbolinks:load', () => {
  flatpickr('.form_date', { dateFormat })
})
