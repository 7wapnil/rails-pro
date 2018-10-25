import 'select2/dist/css/select2.min.css'
import 'select2/dist/js/select2.full.min'
import Noty from 'noty'

const processLabels = () => {
  // Send CSRF header with every ajax request
  $(document).ajaxSend((event, xhr) => {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
  })

  const selectElement = $('#select_labels')
  const saveLabelsBtn = $('#save_labels')

  saveLabelsBtn.on('click', () => {
    let ids = selectElement.val()
    if (!ids.length) {
      ids = [0]
    }

    saveLabelsBtn.prop('disabled', true)

    $.post(selectElement.data('updateUrl'), { labels: { ids } })
      .done(() => {
        new Noty({
          type: 'success',
          text: 'Customer labels updated',
          timeout: 3000
        }).show()
      })
      .fail((err) => {
        new Noty({
          type: 'error',
          text: `${err.status}: ${err.statusText}`,
          timeout: 2000
        }).show()
        saveLabelsBtn.prop('disabled', false)
      })
  })

  selectElement
    .select2({
      minimumInputLength: 0
    })
    .on('change', () => {
      saveLabelsBtn.prop('disabled', false)
    })
}

let loaded = false
if (!loaded) {
  document.addEventListener('turbolinks:load', processLabels)
  loaded = true
}

processLabels()
