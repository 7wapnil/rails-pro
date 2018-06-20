import 'bootstrap/dist/js/bootstrap'
import Noty from 'noty'
import Rails from 'rails-ujs'
import Turbolinks from 'turbolinks'

Rails.start()
Turbolinks.start()

document.addEventListener('turbolinks:load', () => {
  const controllerName = $('body').data('controller')

  $('.nav-link').removeClass('active')
  $(`.nav-link[data-target-controller='${controllerName}']`).addClass('active')

  Noty.overrideDefaults({
    layout: 'topRight',
    theme: 'mint',
    timeout: 2000
  })

  $('.flash-message').each(function() {
    const options = {}
    const typesMap = {
      notice: 'info',
      error: 'error',
      success: 'success',
      alert: 'warning'
    }
    $.each($(this).data(), (key, value) => {
      let attributeValue = value
      if (key === 'type' && typesMap[attributeValue]) {
        attributeValue = typesMap[attributeValue]
      }
      options[key] = attributeValue
    })
    new Noty(options).show()
  })

})
