function highlightCurrent() {
  const actionName = $('body').data('action')

  $('.list-group-item.list-group-item-action').removeClass('active')
  $(`.list-group-item.list-group-item-action[data-target-action='${actionName}']`)
    .addClass('active')
}

let loaded = false

if (!loaded) {
  document.addEventListener('turbolinks:load', highlightCurrent)
  highlightCurrent()
  loaded = true
}

