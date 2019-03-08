describe EntryRequest, '#show' do
  context 'signed in' do
    let(:currency) { create(:currency) }
    let(:rule) do
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 100,
             max_amount: 500)
    end

    let!(:request) do
      create(:entry_request, :succeeded, currency: currency, kind: rule.kind, amount: 200)
    end

    before do
      login_as create(:admin_user), scope: :user
      visit entry_request_path(request)
    end

    it 'shows entry request info' do
      within '.card.request-info' do
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
        expect(page).to have_content(request.external_id)
      end
    end
  end
end
