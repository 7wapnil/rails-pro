import $ from 'jquery';

document.addEventListener('turbolinks:load', () => {
  const bonusSelector = $('#activated_bonus_original_bonus_id');
  const bonusDetailsWrapper = $('#bonus_details');
  const bonuses = $('#bonus_data').data('bonuses');

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
    ].map(key => $(`#activated_bonus_${key}`).val(bonus[key]));
    bonusDetailsWrapper.show();
  }

  function hideBonusDetails() {
    bonusDetailsWrapper.hide();
  }

  bonusSelector.change(() => {
    const bonusId = bonusSelector.val();
    return bonusId ? showBonusDetails(bonusId) : hideBonusDetails()
  })
});
