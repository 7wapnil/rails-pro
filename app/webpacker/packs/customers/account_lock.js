import $ from 'jquery';

$(document).on('turbolinks:load', () => {
  const lockToggleInput = $('#customer_locked');
  const lockReasonSelector = $('#customer_lock_reason');
  const lockedUntilInput = $('#customer_locked_until');
  // Hack for datepicker change event duplicate on clear
  let datePickerValue = lockedUntilInput.val();

  if (!lockToggleInput.prop('checked')) {
    lockToggleInput.attr('disabled', 'disabled')
    lockedUntilInput.attr('disabled', 'disabled')
  }

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
  });

  lockReasonSelector.change(function() {
    if (this.value) {
      enableLockToggleInput();
      lockedUntilInput.removeAttr('disabled');
    } else {
      dropLock();
    }
  });

  lockedUntilInput.change(function() {
    if (!this.value && !lockReasonSelector.val()) dropLock();
    if (datePickerValue !== lockedUntilInput.val()) {
      datePickerValue = lockedUntilInput.val();
    }
  });
});
