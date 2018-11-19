import $ from 'jquery';
import Noty from 'noty';

$(document).on('turbolinks:load', () => {
  const form = $('#update_lock_customer_form');
  const lockToggleInput = $('#customer_locked');
  const lockReasonSelector = $('#customer_lock_reason');
  const lockedUntilInput = $('#customer_locked_until');
  // Hack for datepicker change event duplicate on clear
  let datePickerValue = lockedUntilInput.val();

  if (!lockToggleInput.prop('checked')) {
    lockToggleInput.attr('disabled', 'disabled')
    lockedUntilInput.attr('disabled', 'disabled')
  }

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

  function enableLockToggleInput() {
    lockToggleInput.removeAttr('disabled');
    lockToggleInput.prop('checked', true);
  }

  function dropLock() {
    lockToggleInput.prop('checked', false)
    lockToggleInput.attr('disabled', 'disabled');
    lockReasonSelector.val('');
    lockedUntilInput.val('');
    lockedUntilInput.attr('disabled', 'disabled');
  }

  lockToggleInput.change(function() {
    if (!this.checked) dropLock();
    form.submit();
  });

  lockReasonSelector.change(function() {
    if (this.value) {
      enableLockToggleInput();
      lockedUntilInput.removeAttr('disabled');
    } else {
      dropLock();
    }
    form.submit();
  });

  lockedUntilInput.change(function() {
    if (!this.value && !lockReasonSelector.val()) dropLock();
    if (datePickerValue !== lockedUntilInput.val()) {
      datePickerValue = lockedUntilInput.val();
      form.submit();
    }
  });
});
