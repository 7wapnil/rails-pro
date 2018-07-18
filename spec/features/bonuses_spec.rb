describe 'Bonuses' do
  before do
    login_as create(:admin_user), scope: :user
  end

  describe '#show' do
    subject { create(:bonus) }

    before do
      visit bonus_path(subject)
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

  describe '#new' do
    it 'creates a new bonus' do
      visit new_bonus_path

      within 'form' do
        fill_in :bonus_code, with: 'ARCANE100'
        select :deposit, from: :bonus_kind
        fill_in :bonus_rollover_multiplier, with: 10
        fill_in :bonus_max_rollover_per_bet, with: 150
        fill_in :bonus_expires_at, with: I18n.l(Date.today.end_of_month)
        fill_in :bonus_max_deposit_match, with: 500
        fill_in :bonus_min_odds_per_bet, with: 1.70
        fill_in :bonus_min_deposit, with: 25
        fill_in :bonus_valid_for_days, with: 90

        click_submit
      end

      success_message = I18n.t(:created, instance: I18n.t('entities.bonus'))

      expect(current_path).to eq bonus_path(Bonus.last)
      expect_to_have_notification success_message
    end
  end

  describe '#update' do
    subject { create(:bonus) }

    before do
      visit edit_bonus_path(subject)
    end

    it 'updates an existing bonus' do
      within 'form' do
        fill_in :bonus_rollover_multiplier, with: 100
        click_submit
      end

      success_message = I18n.t(:updated, instance: subject.code)

      expect(current_path).to eq bonus_path(subject)
      expect_to_have_notification success_message
    end
  end

  describe '#destroy' do
    subject { create(:bonus) }

    before do
      visit bonus_path(subject)
      click_on I18n.t(:delete)
    end

    it 'deletes an existing bonus' do
      success_message = I18n.t(:deleted, instance: I18n.t('entities.bonus'))

      expect(current_path).to eq bonuses_path
      expect_to_have_notification success_message
      expect(Bonus.find_by(id: subject.id)).to be nil
    end

    it 'is still possible to recover' do
      expect(Bonus.with_deleted.find_by(id: subject.id)).to be_present
    end
  end
end
