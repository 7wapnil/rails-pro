import 'flatpickr/dist/flatpickr.css'
import 'flatpickr/dist/themes/airbnb.css'

import flatpickr from 'flatpickr'
import moment from 'moment'

const dateFormat = 'd.m.Y';
const dateTimeFormat = 'd.m.Y H:i';
const momentTimeFormat = 'D.MM.YYYY HH:mm';
const toFormattedTime = (str) => {
  if (!str || str.length < 8) {
    return null
  }

  return moment(new Date(str)).format(momentTimeFormat);
}

document.addEventListener('turbolinks:load', () => {
  const datepickerInputs = document.getElementsByClassName('form_date');
  Array.prototype.forEach.call(datepickerInputs, (el) => {
    const time = !!el.dataset.time;
    const format = time ? dateTimeFormat : dateFormat;
    const defaultTime = toFormattedTime(el.value);

    const picker = flatpickr(el, {
      dateFormat: format,
      enableTime: time,
      allowInput: true,
      clickOpens: false,
      defaultDate: defaultTime,
      minDate: el.dataset ? el.dataset.minDate : null,
      maxDate: el.dataset ? el.dataset.maxDate : null
    })

    el.parentElement
      .getElementsByClassName('input-group-append')[0]
      .addEventListener('click', () => { picker.open() })
  });
})
