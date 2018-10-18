import $ from 'jquery';

document.addEventListener('turbolinks:load', () => {
  $('select.priority_toggle').change(function() {
    const path = this.dataset.endpoint;
    const element = this;
    const initialPriority = this.dataset.initialValue;
    const resourceName = this.dataset.resource;
    const priority = this.value;
    const data = { authenticity_token: $('[name="csrf-token"]')[0].content };
    data[resourceName] = { priority };

    $.ajax({
      type: 'PUT',
      url: path,
      data,
      success() {
        element.dataset.initialValue = priority;
        alert('Priority updated!');
      },
      error() {
        element.value = initialPriority;
        alert("Can't change priority!");
      }
    });
  })
});
