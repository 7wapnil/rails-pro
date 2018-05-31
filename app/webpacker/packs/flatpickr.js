import 'flatpickr/dist/flatpickr.css'
import 'flatpickr/dist/themes/airbnb.css'

import flatpickr from 'flatpickr'

const dateFormat = 'j F Y'
const defaultDate = '1 January 1990'

document.addEventListener('turbolinks:load', () => {
  flatpickr('.form_date', { dateFormat, defaultDate })
})
