import $ from 'jquery';
import Noty from 'noty';

const copy = require('copy-text-to-clipboard');

document.addEventListener('turbolinks:load', () => {
  $('button.reset_password').click(function() {
    const path = this.dataset.endpoint;
    const data = { authenticity_token: $('[name="csrf-token"]')[0].content };
    let newPassword;
    $.ajax({
      type: 'POST',
      url: path,
      async: false,
      data,
      success(response) {
        newPassword = response.password;
      },
      error(error) {
        new Noty({
          type: 'error',
          text: `${error.status}: ${error.statusText}`,
          timeout: 3000
        }).show()
      }
    });
    copy(newPassword);
    new Noty({
      type: newPassword ? 'success' : 'error',
      text: newPassword ? 'Password copied to clipboard'
        : 'Couldn\'t copy password',
      timeout: 3000
    }).show()
  })
});
