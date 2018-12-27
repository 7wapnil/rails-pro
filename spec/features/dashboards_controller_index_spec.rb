describe DashboardsController, '#index' do
  context 'signed in' do
    before do
      login_as create(:admin_user), scope: :user
      visit dashboard_path
    end

    it 'shows "Search Bets" section' do
      expect_to_have_section 'bets'
    end

    it 'shows "Search Customers" section' do
      expect_to_have_section 'customers'
    end

    context 'search' do
      it 'doesn\'t redirect to bets page' do
        within '.bet_search' do
          click_submit
        end
        expect(page).to have_current_path(dashboard_path, ignore_query: true)
      end

      it 'doesn\'t redirect to customers page' do
        within '.customer_search' do
          click_submit
        end
        expect(page).to have_current_path(dashboard_path, ignore_query: true)
      end
    end
  end
end
