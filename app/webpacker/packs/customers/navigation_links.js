function highlightCurrent() {
  const actionName = $('body').data('action')
  const controllerName = $('body').data('controller')
  const action = `${controllerName}#${actionName}`

  $('.list-group-item.list-group-item-action').removeClass('active')
  $(`.list-group-item.list-group-item-action[data-target-action='${action}']`)
    .addClass('active')
}

let loaded = false

if (!loaded) {
  document.addEventListener('turbolinks:load', highlightCurrent)
  highlightCurrent()
  loaded = true
}

