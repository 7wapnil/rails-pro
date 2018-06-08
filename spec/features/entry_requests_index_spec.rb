describe 'EntryRequests#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

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

    before do
      create_list(:entry_request, 5, payload: payload)

      login_as create(:admin_user), scope: :user
      visit backoffice_entry_requests_path
    end

    it 'shows entry requests list' do
      within 'table.table' do
        EntryRequest.limit(per_page_count).each do |request|
          expected_date = request
                          .created_at
                          .strftime(Date::DATE_FORMATS[:long_date_time])
          expected_kind = I18n.t(EntryKinds::KINDS
                                  .key(request.payload.kind))
          expected_amount = "200.00 #{request.payload.currency.code}"

          expect(page).to have_content(expected_date)
          expect(page).to have_content(expected_kind)
          expect(page).to have_content(request.payload.customer.full_name)
          expect(page).to have_content(expected_amount)
        end
      end
    end
  end
end
