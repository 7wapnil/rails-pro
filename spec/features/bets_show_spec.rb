require 'action_view'

describe Bet, '#show' do
  include ActionView::Helpers::NumberHelper
  subject { create(:bet, :with_bet_leg) }

  let(:bet_trait) { Entry::BET.to_sym }
  let(:win_trait) { Entry::WIN.to_sym }
  let!(:bet_entry) { create(:entry, bet_trait, origin: subject) }
  let!(:win_entry) { create(:entry, win_trait, origin: subject) }
  let(:bet_leg) { subject.bet_legs.first }

  context 'page content' do
    before do
      login_as create(:admin_user), scope: :user
      visit bet_path(subject)
    end

    it 'shows bet details' do
      expect(page).to have_content(subject.id)
      expect(page).to have_content(subject.customer.username)
      expect(page).to have_content(bet_leg.odd.market.event.name)
      expect(page).to have_content(bet_leg.odd.market.name)
      expect(page).to have_content(bet_leg.odd.name)
      expect(page).to have_content(bet_leg.odd_value)
      expect(page).to have_content(subject.amount)
      expect(page).to have_content(
        number_with_precision(bet_leg.odd_value * subject.amount, precision: 2)
      )

      expect(page).to have_content(I18n.t("kinds.#{bet_trait}"))
      expect(page).to have_content(I18n.t("kinds.#{win_trait}"))
      expect(page).to have_content(bet_entry.amount)
      expect(page).to have_content(win_entry.amount)
    end
  end
end
