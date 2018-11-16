import $ from 'jquery';
import Noty from 'noty';

$(document).on('turbolinks:load', () => {
  const form = $('#update_lock_customer_form');
  const lockToggleInput = $('#customer_locked');
  const lockReasonSelector = $('#customer_lock_reason');
  const lockedUntilInput = $('#customer_locked_until');

  form.submit(function(e) {
    e.preventDefault();
    const reason = lockReasonSelector.val().length ? lockReasonSelector.val() : null;
    const lockedUntil = lockedUntilInput.val().length ? lockedUntilInput.val() : null;
    $.ajax({
      type: 'POST',
      url: this.action,
      data: {
        locked: lockToggleInput.prop('checked'),
        lock_reason: reason,
        locked_until: lockedUntil,
        authenticity_token: $('[name="csrf-token"]')[0].content
      },
      success(response) {
        new Noty({
          type: 'success',
          text: response.message,
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

  $('#customer_locked, #customer_lock_reason, #customer_locked_until').change(() => {
    form.submit();
  });
});
