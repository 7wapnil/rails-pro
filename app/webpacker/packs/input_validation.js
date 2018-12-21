document.addEventListener('turbolinks:load', () => {
  function allowOnlyLetters(event) {
    const inputValue = event.which;
    if (!(inputValue >= 65 && inputValue <= 120)) {
      event.preventDefault();
    }
  }
  $('input[data-only-letters]').bind('keypress', allowOnlyLetters);
});
