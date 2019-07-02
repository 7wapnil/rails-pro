describe Customer, '#transactions' do
  let(:customer) { create(:customer) }

  let(:per_page_count) { 20 }

  let!(:the_transaction) do
    create(:deposit, :with_customer, customer: customer)
  end

  before do
    create_list(:deposit, 8, :with_customer, customer: customer)
    create_list(:withdrawal, 8, :with_customer, customer: customer)

    login_as create(:admin_user), scope: :user
    visit transactions_customer_path(customer)
  end

  it_behaves_like 'transactions list'

  context 'pagination' do
    it 'is shown' do
      create_list(:withdrawal, 10, :with_customer, customer: customer)
      visit transactions_customer_path(customer)
      expect(page).to have_selector('ul.pagination')
    end

    it 'is hidden' do
      expect(page).not_to have_selector('ul.pagination')
    end
  end
end
