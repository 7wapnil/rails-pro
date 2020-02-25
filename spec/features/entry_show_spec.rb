describe Entry, '#show' do
  context 'signed in' do
    let(:currency) { create(:currency) }
    let(:rule) do
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 100,
             max_amount: 500)
    end

    let!(:entry) do
      create(:entry, currency: currency, kind: rule.kind, amount: 200)
    end

    before do
      login_as create(:admin_user), scope: :user
      visit entry_path(entry)
    end

    context 'entry info' do
      let(:entry_card) { '.card.entry-info' }

      it 'shows :created_at' do
        within entry_card do
          # #squish is a temporary hack to fix a bug in `I18n.l` where
          # the value is returned with an extra space
          # between the date and the time
          expected_date = I18n.l(entry.created_at, format: :long).squish

          expect(page).to have_content(expected_date)
        end
      end

      it 'shows :kind' do
        within entry_card do
          expect(page).to have_content(entry.kind.capitalize)
        end
      end

      it 'shows :amount' do
        within entry_card do
          expected_amount = "200.00 #{entry.currency.code}"

          expect(page).to have_content(expected_amount)
        end
      end

      it 'shows :external_id' do
        within entry_card do
          expect(page).to have_content(entry.external_id)
        end
      end
    end
  end
end
