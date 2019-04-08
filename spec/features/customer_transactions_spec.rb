describe Customer, '#transactions' do
  let(:customer) { create(:customer) }

  let(:per_page_count) { 20 }

  let!(:the_transaction) do
    create(
      :entry_request,
      :deposit,
      status:     EntryRequest::SUCCEEDED,
      mode:       EntryRequest::BITCOIN,
      created_at: Faker::Time.backward(5),
      customer: customer
    )
  end

  before do
    create_list(:entry_request, 8, :deposit, customer: customer)
    create_list(:entry_request, 8, :withdraw, customer: customer)

    login_as create(:admin_user), scope: :user
    visit transactions_customer_path(customer)
  end

  it_behaves_like 'transactions list'

  context 'pagination' do
    it 'is shown' do
      create_list(:entry_request, 10, :withdraw, customer: customer)
      visit transactions_customer_path(customer)
      expect(page).to have_selector('ul.pagination')
    end

    it 'is hidden' do
      expect(page).not_to have_selector('ul.pagination')
    end
  end
end
