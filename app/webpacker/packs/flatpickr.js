import 'flatpickr/dist/flatpickr.css'
import 'flatpickr/dist/themes/airbnb.css'

import flatpickr from 'flatpickr'

const dateFormat = 'j F Y';
const dateTimeFormat = 'j F Y H:i';

document.addEventListener('turbolinks:load', () => {
  const datepickerInputs = document.getElementsByClassName('form_date');
  Array.prototype.forEach.call(datepickerInputs, (el) => {
    const time = !!el.dataset.time;
    const format = time ? dateFormat : dateTimeFormat;

    flatpickr(el, {
      format,
      enableTime: time,
      minDate: el.dataset ? el.dataset.minDate : null,
      maxDate: el.dataset ? el.dataset.maxDate : null
    })
  })
})
