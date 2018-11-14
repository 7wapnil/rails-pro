describe 'Customers#bets' do
  let(:customer) { create(:customer) }
  let(:page_path) { bets_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  it 'shows customer bets section' do
    expect(page).to have_selector('#customer-bets')
  end
end
