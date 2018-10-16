describe 'Bets#show' do
  subject { create(:bet) }

  context 'page content' do
    before do
      login_as create(:admin_user), scope: :user
      visit bet_path(subject)
    end

    it 'shows bet details' do
      expect(page).to have_content(subject.customer.username)
      expect(page).to have_content(subject.id)
      expect(page).to have_content(subject.odd.market.event.name)
      expect(page).to have_content(subject.odd.market.name)
      expect(page).to have_content(subject.odd_value)
      expect(page).to have_content(subject.odd.name)
    end
  end
end
