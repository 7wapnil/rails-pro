describe Customer, '#betting_limits' do
  let(:customer) { create(:customer) }
  let!(:title) { create(:title) }
  let(:page_path) { betting_limits_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  context 'limits' do
    it 'shows customers betting limit sections' do
      expect_to_have_section 'global-limit'
      expect_to_have_section 'limits-by-sport'
    end
  end

  context 'global betting limit form' do
    it 'shows global betting limit form' do
      expect(page)
        .to have_selector 'form#new_betting_limit:not([data-title-id])'
    end

    it 'creates customer global betting limit' do
      visit page_path

      within '.betting-limit-form:not([data-title-id])' do
        fill_in :betting_limit_live_bet_delay, with: 10
        fill_in :betting_limit_user_max_bet, with: 1000
        fill_in :betting_limit_max_loss, with: 1000
        fill_in :betting_limit_max_win, with: 1000
        fill_in :betting_limit_user_stake_factor, with: 0.1
        fill_in :betting_limit_live_stake_factor, with: 0.1
        click_submit
      end

      within '.container' do
        expect_to_have_notification I18n.t(
          :created,
          instance: I18n.t('entities.betting_limit')
        )
      end
    end

    it 'updates customer global betting limit' do
      create(:betting_limit, customer: customer, title: nil)
      visit page_path

      within '.betting-limit-form:not([data-title-id])' do
        fill_in :betting_limit_live_bet_delay, with: 20
        fill_in :betting_limit_user_max_bet, with: 2000
        fill_in :betting_limit_max_loss, with: 2000
        fill_in :betting_limit_max_win, with: 2000
        fill_in :betting_limit_user_stake_factor, with: 0.2
        fill_in :betting_limit_live_stake_factor, with: 0.2
        click_submit
      end

      within '.container' do
        expect_to_have_notification I18n.t(
          :updated,
          instance: I18n.t('entities.betting_limit')
        )
      end
    end
  end

  context 'betting limit by sport form' do
    it 'shows betting limit by sport form' do
      expect(page).to have_selector(
        ".betting-limit-form[data-title-id='#{title.id}']"
      )
    end

    it 'creates customer betting limit by sport' do
      visit page_path

      within ".betting-limit-form[data-title-id='#{title.id}']" do
        fill_in :betting_limit_live_bet_delay, with: 30
        fill_in :betting_limit_user_max_bet, with: 3000
        fill_in :betting_limit_max_loss, with: 3000
        fill_in :betting_limit_max_win, with: 3000
        fill_in :betting_limit_user_stake_factor, with: 0.3
        fill_in :betting_limit_live_stake_factor, with: 0.3
        click_submit
      end

      within '.container' do
        expect_to_have_notification I18n.t(
          :created,
          instance: I18n.t('entities.betting_limit')
        )
      end
    end

    it 'updates customer betting limit by sport' do
      create(:betting_limit, customer: customer, title: title)
      visit page_path

      within ".betting-limit-form[data-title-id='#{title.id}']" do
        fill_in :betting_limit_live_bet_delay, with: 40
        fill_in :betting_limit_user_max_bet, with: 4000
        fill_in :betting_limit_max_loss, with: 4000
        fill_in :betting_limit_max_win, with: 4000
        fill_in :betting_limit_user_stake_factor, with: 0.4
        fill_in :betting_limit_live_stake_factor, with: 0.4
        click_submit
      end

      within '.container' do
        expect_to_have_notification I18n.t(
          :updated,
          instance: I18n.t('entities.betting_limit')
        )
      end
    end
  end
end
