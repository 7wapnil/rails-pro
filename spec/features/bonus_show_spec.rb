describe 'Bonuses#show' do
  subject { create(:bonus) }

  before do
    login_as create(:admin_user), scope: :user
    visit backoffice_bonus_path(subject)
  end

  it 'shows bonus details' do
    within '.card.bonus-details' do
      expect(page).to have_content(subject.code)
      expect(page).to have_content(subject.kind)
      expect(page).to have_content(subject.rollover_multiplier)
      expect(page).to have_content(subject.max_rollover_per_bet)
      expect(page).to have_content(subject.max_deposit_match)
      expect(page).to have_content(subject.min_odds_per_bet)
      expect(page).to have_content(subject.min_deposit)
      expect(page).to have_content(subject.valid_for_days)

      # #squish is a temporary hack to fix a bug in `I18n.l` where
      # the value is returned with an extra space
      # between the date and the time
      expect(page).to have_content(I18n.l(subject.expires_at).squish)
    end
  end
end
