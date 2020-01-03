# frozen_string_literal: true

describe Customers::EveryMatrixTransactionsController, '#index' do
  let(:customer) { create(:customer) }
  let(:page_path) { customer_every_matrix_transactions_path(customer) }
  let(:admin) { create(:admin_user) }
  let(:rand_number) { rand(4..7) }
  let!(:primary_currency) { create(:currency, :primary) }

  before do
    create_list(:every_matrix_transaction, rand_number,
                :random, customer: customer)

    login_as admin, scope: :user
    visit page_path
  end

  it 'shows customer casino spins section' do
    expect(page).to have_selector('.table.em_transactions')
  end

  it 'shows exactly number of elements' do
    within 'table.table.em_transactions tbody' do
      transactions_ids = page.all('tr').map do |row|
        row[:id].delete('customertransaction-').to_i
      end

      expect(transactions_ids.length).to eq(rand_number)
    end
  end
end
