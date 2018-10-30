import 'select2/dist/css/select2.min.css'
import 'select2/dist/js/select2.full.min'
import Noty from 'noty'

const processLabels = () => {
  // Send CSRF header with every ajax request
  $(document).ajaxSend((event, xhr) => {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
  });

  $('.save_labels').click(function() {
    const selectorElement = $(`#${this.dataset.labelSelector}`);
    const trigger = this;
    let ids = selectorElement.val()
    if (!ids.length) {
      ids = [0]
    }
    $.post(selectorElement.data('updateUrl'), { labels: { ids } })
      .done(() => {
        new Noty({
          type: 'success',
          text: 'Labels updated',
          timeout: 3000
        }).show()
        trigger.disabled = true;
      })
      .fail((err) => {
        new Noty({
          type: 'error',
          text: `${err.status}: ${err.statusText}`,
          timeout: 2000
        }).show();
        trigger.disabled = false;
      })
  });

  $('.labels_selector').select2({
    minimumInputLength: 0
  }).on('change', (element) => {
    $(`[data-label-selector='${element.target.id}']`).prop('disabled', false)
  });
};

let loaded = false;
if (!loaded) {
  document.addEventListener('turbolinks:load', processLabels)
  loaded = true
}

processLabels();
