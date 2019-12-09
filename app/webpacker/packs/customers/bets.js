import $ from 'jquery';

document.addEventListener('turbolinks:load', () => {
  $('.combo-bets-collapse-link').click((event) => {
    event.preventDefault()

    const betId = event.target.id.split('-')[2]

    $(`.collapse.bet-${betId}`)
      .toggleClass('show')
      .get(-1)
      .scrollIntoView(false);
  })
});
