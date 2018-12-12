import $ from 'jquery';

document.addEventListener('turbolinks:load', () => {
  const bonusSelector = $('#customer_bonus_original_bonus_id');
  const bonusDetailsWrapper = $('#bonus-details');
  const bonuses = $('#bonus-data').data('bonuses');

  function showBonusDetails(id) {
    const bonus = bonuses.find(el => parseInt(el.id, 10) === parseInt(id, 10));
    [
      'kind',
      'rollover_multiplier',
      'max_rollover_per_bet',
      'max_deposit_match',
      'min_odds_per_bet',
      'min_deposit',
      'valid_for_days',
      'percentage'
    ].map(key => $(`#customer_bonus_${key}`).val(bonus[key]));
    bonusDetailsWrapper.removeClass('d-none').show();
  }

  function hideBonusDetails() {
    bonusDetailsWrapper.hide();
  }

  bonusSelector.change(() => {
    const bonusId = bonusSelector.val();
    return bonusId ? showBonusDetails(bonusId) : hideBonusDetails()
  })
});
