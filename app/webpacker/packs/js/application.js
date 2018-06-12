import 'bootstrap/dist/js/bootstrap'
import Rails from 'rails-ujs'
import Turbolinks from 'turbolinks'

Rails.start()
Turbolinks.start()

document.addEventListener('turbolinks:load', () => {
  console.log('reloaded')

  const controllerName = $('body').data('controller')

  $('.nav-link').removeClass('active')
  $(`.nav-link[data-target-controller='${controllerName}']`).addClass('active')
})
