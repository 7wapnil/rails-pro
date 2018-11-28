import $ from 'jquery';
import { countries } from 'countries-list';
import { isValidNumber } from 'libphonenumber-js';

document.addEventListener('turbolinks:load', () => {
  const countrySelect = $('.country-select');
  const phoneInput = $('.phone-input');

  function createCountryOption(country) {
    const el = document.createElement('option');
    $(el)
      .attr('value', country.name)
      .text(country.name);
    return el;
  }

  countrySelect
    .html('')
    .append(Object
      .values(countries)
      .map(country => createCountryOption(country)))
    .val(countrySelect.data('current'));
  countrySelect.change(() => {
    if (phoneInput) {
      phoneInput.val('');
      Object
        .values(countries)
        .forEach((country) => {
          if (country.name === countrySelect.val()) {
            phoneInput.val(`+${country.phone}`)
              .trigger('keyup');
          }
        });
    }
  });

  if (phoneInput) {
    phoneInput.keyup(() => {
      const valid = isValidNumber(phoneInput.val());
      if (valid) {
        phoneInput.removeClass('is-invalid')
          .addClass('is-valid');
      } else {
        phoneInput.removeClass('is-valid')
          .addClass('is-invalid');
      }
      return true;
    });
  }
});
