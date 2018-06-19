describe 'Customers#activity' do
  let(:customer) { create(:customer) }
  let(:page_path) { activity_backoffice_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  context 'activity' do
    it 'shows activity section' do
      expect_to_have_section 'activity'
    end

    it 'shows available entries' do
      wallet = create(:wallet, customer: customer)
      rule = create(:entry_currency_rule,
                    currency: wallet.currency,
                    min_amount: 10,
                    max_amount: 500)
      create_list(:entry, 10, wallet: wallet, kind: rule.kind, amount: 100)

      visit page_path

      within '.activity' do
        customer.entries.each do |entry|
          expect(page).to have_content entry.kind
          expect(page).to have_content entry.amount
          expect(page).to have_content entry.wallet.currency_code
        end
      end
    end

    it 'shows no records note' do
      expect(page).to have_content I18n.t(:no_records)
    end
  end
end
