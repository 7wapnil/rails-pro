import $ from 'jquery';
import Noty from 'noty';

$(document).on('turbolinks:load', () => {
  $('.locked_until').change(function() {
    const path = this.dataset.endpoint;
    const lockedUntil = this.value;
    $.ajax({
      type: 'POST',
      url: path,
      data: { locked_until: lockedUntil, authenticity_token: $('[name="csrf-token"]')[0].content },
      success() {
        new Noty({
          type: 'success',
          text: 'Customer locked until date was changed',
          timeout: 3000
        }).show()
      },
      error(error) {
        new Noty({
          type: 'error',
          text: `${error.status}: ${error.statusText}`,
          timeout: 3000
        }).show()
      }
    })
  });
});
