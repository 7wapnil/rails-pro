describe Customer, '#activity' do
  let(:customer) { create(:customer) }
  let(:page_path) { activity_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  context 'activity' do
    let(:rule) do
      create(:entry_currency_rule,
             currency: wallet.currency,
             min_amount: 10,
             max_amount: 500)
    end
    let(:wallet) { create(:wallet, customer: customer) }
    let(:authorization_time_formatted) { '11 September 2018 16:29:16' }
    let(:authorization_time) { Time.zone.local(2018, 9, 11, 16, 29, 16) }

    it 'shows activity section' do
      expect_to_have_section 'activity'
    end

    it 'shows available entries' do
      create_list(
        :entry,
        10,
        wallet: wallet,
        kind: rule.kind,
        amount: 100,
        authorized_at: authorization_time
      )

      visit page_path

      within '.activity' do
        customer.entries.each do |entry|
          expect(page).to have_content entry.kind
          expect(page).to have_content entry.amount
          expect(page).to have_content entry.wallet.currency_code
          expect(page).to have_content authorization_time_formatted
        end
      end
    end

    it 'shows no records note' do
      expect(page).to have_content I18n.t(:no_records)
    end

    it 'allows sorting by date' do
      creation_date = Time.zone.local(2018, 9, 10, 10, 10, 10)
      creation_date_formatted = '10 September 2018 10:10:10'
      entries = create_list(
        :entry,
        10,
        wallet: wallet,
        kind: rule.kind,
        amount: 100,
        authorized_at: authorization_time
      )
      latest_entry = entries.first
      latest_entry.update(created_at: creation_date)
      visit page_path
      click_link('Created at')
      first_entry_date = page.first('table > tbody tr td')

      expect(first_entry_date.text).to eq(creation_date_formatted)
    end
  end
end
