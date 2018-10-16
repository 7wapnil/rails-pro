describe 'Bets#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:bet, 5)

      login_as create(:admin_user), scope: :user
      visit bets_path
    end

    it 'shows bets list' do
      within 'table.table' do
        Bet.limit(per_page_count).each do |bet|
          expect(page).to have_content(bet.customer.username)
          expect(page).to have_content(bet.id)
          expect(page).to have_content(bet.odd.market.event.name)
          expect(page).to have_content(bet.odd.market.name)
          expect(page).to have_content(bet.odd_value)
          expect(page).to have_content(bet.odd.name)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:bet, 10)
        visit bets_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end
  end
end
