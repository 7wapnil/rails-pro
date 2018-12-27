require 'action_view'

describe Bet, '#show' do
  include ActionView::Helpers::NumberHelper
  subject { create(:bet) }

  context 'page content' do
    before do
      login_as create(:admin_user), scope: :user
      visit bet_path(subject)
    end

    it 'shows bet details' do
      expect(page).to have_content(subject.id)
      expect(page).to have_content(subject.customer.username)
      expect(page).to have_content(subject.odd.market.event.name)
      expect(page).to have_content(subject.odd.market.name)
      expect(page).to have_content(subject.odd.name)
      expect(page).to have_content(subject.odd_value)
      expect(page).to have_content(subject.amount)
      expect(page).to have_content(
        number_with_precision(subject.odd_value * subject.amount, precision: 2)
      )
      expect(page).to have_content(subject.actual_payout)
    end
  end
end
