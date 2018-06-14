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

    before do
      create_list(:entry_request,
                  5,
                  currency: currency,
                  kind: rule.kind,
                  amount: 200)

      login_as create(:admin_user), scope: :user
      visit backoffice_entry_requests_path
    end

    it 'shows entry requests list' do
      within 'table.table' do
        EntryRequest.limit(per_page_count).each do |request|

          # #squish is a temporary hack to fix a bug in `I18n.l` where
          # the value is returned with an extra space
          # between the date and the time
          expected_date = I18n.l(request.created_at, format: :long).squish

          expected_kind = I18n.t("kinds.#{request.kind}")
          expected_amount = "200.00 #{request.currency.code}"

          expect(page).to have_content(expected_date)
          expect(page).to have_content(expected_kind)
          expect(page).to have_content(request.customer.full_name)
          expect(page).to have_content(expected_amount)
        end
      end
    end
  end
end
