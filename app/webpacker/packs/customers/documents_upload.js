
const initDocumentsUpload = () => {
  $('input[type=file]').on('change', (e) => {
    const { target: { files } } = e
    if (files.length > 0) {
      const name = $(e.target).attr('name')
      $(`[data-target=${name}]`).text(files[0].name)
    }
  })

  $('.upload-form').on('submit', () => {
    $('[type=submit]').prop('disabled', true)
  })
}

let docsLoaded = false
if (!docsLoaded) {
  document.addEventListener('turbolinks:load', initDocumentsUpload)
  initDocumentsUpload()
  docsLoaded = true
}
