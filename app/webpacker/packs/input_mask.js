import Inputmask from 'inputmask';

document.addEventListener('turbolinks:load', () => {
  Inputmask().mask(document.querySelectorAll('input'));
});
