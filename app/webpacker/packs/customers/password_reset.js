import $ from 'jquery';
import Noty from 'noty';

const copy = require('copy-text-to-clipboard');

document.addEventListener('turbolinks:load', () => {
  $('button.reset_password').click(function() {
    if (!confirm(this.dataset.confirmation)) return; // eslint-disable-line no-restricted-globals
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
      text: newPassword ? this.dataset.successMessage
        : this.dataset.errorMessage,
      timeout: 3000
    }).show()
  })
});
