import $ from 'jquery';
import Noty from 'noty';

$(document).on('turbolinks:load', () => {
  $('.locked_toggle').change(function() {
    const path = this.dataset.endpoint;
    const locked = this.checked;
    const toggleElement = this;
    $.ajax({
      type: 'POST',
      url: path,
      data: { locked, authenticity_token: $('[name="csrf-token"]')[0].content },
      success() {
        new Noty({
          type: 'success',
          text: 'Customer locked status was changed',
          timeout: 3000
        }).show()
      },
      error(error) {
        toggleElement.checked = !locked;
        new Noty({
          type: 'error',
          text: `${error.status}: ${error.statusText}`,
          timeout: 3000
        }).show()
      }
    })
  });
});
