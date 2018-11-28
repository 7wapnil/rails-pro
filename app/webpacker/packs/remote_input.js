import $ from 'jquery'
import Noty from 'noty'

$(document).on('turbolinks:load', () => {
  $("input[type='checkbox'].remote_input").change(function() {
    const path = this.dataset.endpoint
    const attributeName = this.name
    const resourceName = this.dataset.resource
    const data = {}
    data[resourceName] = {}
    data[resourceName][attributeName] = this.checked;
    data.authenticity_token = $('[name="csrf-token"]')[0].content
    const requestMethod = this.dataset.method
    const element = this
    $.ajax({
      type: requestMethod,
      dataType: 'JSON',
      url: path,
      data,
      success(response) {
        new Noty({
          type: 'success',
          text: response.message,
          timeout: 3000
        }).show()
      },
      error(err) {
        element.value = !element.value
        new Noty({
          type: 'error',
          text: `${err.status}: ${err.statusText}`,
          timeout: 2000
        }).show();
      }
    })
  });
});
