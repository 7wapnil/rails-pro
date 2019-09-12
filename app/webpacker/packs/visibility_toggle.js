import $ from 'jquery';

$(document).on('turbolinks:load', () => {
  $('.visibility_toggle').change(function() {
    const path = this.dataset.endpoint;
    const { model } = this.dataset;
    const visible = this.checked;
    const toggleElement = this;
    $.ajax({
      type: 'PATCH',
      url: path,
      data: {
        [model]: { visible },
        authenticity_token: $('[name="csrf-token"]')[0].content
      },
      error() {
        toggleElement.checked = !visible;
        alert("Can't change visibility.");
      }
    })
  });
});
