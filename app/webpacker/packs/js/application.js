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
    $.each($(this).data(), (key, value) => {
      options[key] = value
    })
    new Noty(options).show()
  })

})
