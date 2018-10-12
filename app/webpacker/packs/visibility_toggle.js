import $ from 'jquery';

document.addEventListener('turbolinks:load', () => {
  function toggleBadge(visible, id) {
    const visibleOptions = { style: 'badge-success', text: 'visible' };
    const invisibleOptions = { style: 'badge-danger', text: 'invisible' };

    const badgeOptions = visible === true ? visibleOptions : invisibleOptions;

    const badgeElement = $(`#${id}`);
    badgeElement.attr('class', `badge ${badgeOptions.style}`);
    badgeElement.text(badgeOptions.text);
  }
  $('.visibility_toggle').change(function() {
    const path = this.dataset.endpoint;
    const visible = this.checked;
    const badgeId = this.dataset.badge;
    $.ajax({
      type: 'POST',
      url: path,
      data: { visible, authenticity_token: $('[name="csrf-token"]')[0].content },
      success() {
        toggleBadge(visible, badgeId);
      },
      error() {
        alert("Can't change visibility.");
      }
    })
  });
});
