document.addEventListener('turbolinks:load', () => {
  const actionName = $('body').data('action')

  $('.list-group-item.list-group-item-action').removeClass('active')
  $(`.list-group-item.list-group-item-action[data-target-action='${actionName}']`)
    .addClass('active')
})
