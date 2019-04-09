describe 'Transaction', '#index' do
  let(:per_page_count) { 20 }
  let!(:the_transaction) do
    create(
      :entry_request,
      :deposit,
      status:     EntryRequest::SUCCEEDED,
      mode:       EntryRequest::BITCOIN,
      created_at: Faker::Time.backward(5)
    )
  end

  before do
    create_list(:entry_request, 8, :deposit)
    create_list(:entry_request, 8, :withdraw)

    login_as create(:admin_user), scope: :user
    visit transactions_path
  end

  it_behaves_like 'transactions list'

  context 'pagination' do
    it 'is shown' do
      create_list(:entry_request, 10, :withdraw)
      visit transactions_path
      expect(page).to have_selector('ul.pagination')
    end

    it 'is hidden' do
      expect(page).not_to have_selector('ul.pagination')
    end
  end
end
