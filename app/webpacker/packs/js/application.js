import 'bootstrap/dist/js/bootstrap'
import Noty from 'noty'
import Rails from 'rails-ujs'
import Turbolinks from 'turbolinks'
import 'select2/dist/js/select2.full.min'

Rails.start()
Turbolinks.start()

document.addEventListener('turbolinks:load', () => {
  const controllerName = $('body').data('controller')
  const currentPath = window.location.pathname + window.location.search
  $('.nav-link').removeClass('active')
  $(`.nav-link[data-target-controller='${controllerName}']`).addClass('active')

  $(`.nav-tabs a.nav-link[href='${currentPath}']`).addClass('active')
  $('[data-button-back]').click(() => {
    window.history.back()
  })

  Noty.overrideDefaults({
    layout: 'topRight',
    theme: 'mint',
    timeout: 2000
  })

  $('.flash-message').each((index, el) => {
    const options = el.dataset
    const typesMap = {
      notice: 'info',
      error: 'error',
      success: 'success',
      alert: 'warning'
    }
    if (options && options.type) {
      options.type = typesMap[options.type]
    }
    new Noty(options).show()
  })
  $('.multi-select').select2()
})
