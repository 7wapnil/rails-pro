describe 'EntryRequests#show' do
  context 'signed in' do
    let(:currency) { create(:currency) }
    let(:rule) do
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 100,
             max_amount: 500)
    end

    let!(:request) do
      create(:entry_request, currency: currency, kind: rule.kind, amount: 200)
    end

    before do
      login_as create(:admin_user), scope: :user
      visit backoffice_entry_request_path(request)
    end

    it 'shows entry request info' do
      within '.card.request-info' do
        expected_date = I18n.l(request.created_at, format: :long)
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
