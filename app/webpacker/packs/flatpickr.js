import 'flatpickr/dist/flatpickr.css'
import 'flatpickr/dist/themes/airbnb.css'

import flatpickr from 'flatpickr'

const dateFormat = 'j F Y';

document.addEventListener('turbolinks:load', () => {
  const datepickerInputs = document.getElementsByClassName('form_date');
  Array.prototype.forEach.call(datepickerInputs, (el) => {
    flatpickr(el, {
      dateFormat,
      minDate: el.dataset ? el.dataset.minDate : null,
      maxDate: el.dataset ? el.dataset.maxDate : null
    })
  })
})
