const maxFileSize = 2097152;

const initDocumentsUpload = () => {
  const errors = []

  $('input[type=file]').on('change', (e) => {
    const index = errors.findIndex(name => name === e.target.id)
    if (index !== -1) errors.splice(index, 1)

    if (errors.length === 0) $('[type=submit]').prop('disabled', false)
    const { target: { files } } = e
    if (files.length > 0) {
      const name = $(e.target).attr('name')
      $(`[data-target=${name}]`).text(files[0].name)
    }

    if (files[0].size > maxFileSize) {
      e.preventDefault();
      alert('File size exceeds maximum limit!');
      e.target.value = '';
      $('[type=submit]').prop('disabled', true)

      if (errors.findIndex(name => name === e.target.id) === -1) {
        errors.push(e.target.id)
      }
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
