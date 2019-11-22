const ALLOWED_NAME_SYMBOLS_REGEX = /^([a-zA-Z\-\s]{1})$/

document.addEventListener('turbolinks:load', () => {
  function allowOnlyLetters(event) {
    if (!ALLOWED_NAME_SYMBOLS_REGEX.test(event.key)) {
      event.preventDefault();
    }
  }
  $('input[data-only-letters]').bind('keypress', allowOnlyLetters);
});
