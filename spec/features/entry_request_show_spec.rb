describe 'EntryRequests#show' do
  context 'signed in' do
    let(:currency) { create(:currency) }
    let(:rule) do
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 100,
             max_amount: 500)
    end

    let(:payload) do
      build(:entry_request_payload,
            currency_code: rule.currency.code,
            kind: rule.kind,
            amount: 200)
    end

    let(:entry_request) { create(:entry_request, payload: payload) }

    before do
      login_as create(:admin_user), scope: :user
      visit backoffice_entry_request_path(entry_request)
    end

    it 'shows entry request info' do
      within '.card.request-info' do
        expected_date = entry_request
                        .created_at
                        .strftime(Date::DATE_FORMATS[:long_date_time])
        expected_kind = I18n.t(EntryKinds::KINDS
                                 .key(entry_request.payload.kind))
        expected_amount = "200.00 #{entry_request.payload.currency.code}"

        expect(page).to have_content(expected_date)
        expect(page).to have_content(expected_kind)
        expect(page).to have_content(entry_request.payload.customer.full_name)
        expect(page).to have_content(expected_amount)
      end
    end
  end
end
