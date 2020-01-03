describe EveryMatrix::Transaction, '#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }
    let!(:currency) { create(:currency, :primary) }

    before do
      create_list(:every_matrix_transaction, 5, :random)

      login_as create(:admin_user), scope: :user
      visit every_matrix_transactions_path
    end

    def transaction_ids(page)
      page.all('tr').map do |row|
        row[:id].delete('transaction-').to_i
      end
    end

    it 'shows transactions list' do
      within 'table.table.em_transactions' do
        EveryMatrix::Transaction.limit(per_page_count).each do |transaction|
          expect(page).to have_content(transaction.id)
          expect(page).to have_content(transaction.type.demodulize)
          expect(page).to have_content(transaction.amount)
          expect(page).to have_content(transaction.currency)
          expect(page).to have_content(transaction.vendor.name)
          expect(page).to have_content(transaction.content_provider.name)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:every_matrix_transaction, per_page_count, :random)

        visit every_matrix_transactions_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    describe 'sorting' do
      context 'by ID' do
        it 'sorts by default in DESC order' do
          within 'table.table.em_transactions tbody' do
            expect(transaction_ids(page))
              .to eq(transaction_ids(page).sort.reverse)
          end
        end

        it 'sorts in ASC order' do
          click_link('Transaction ID')
          within 'table.table.em_transactions tbody' do
            expect(transaction_ids(page)).to eq(transaction_ids(page).sort)
          end
        end
      end

      context 'by dates interval' do
        it 'sorts by default starts from today' do
          start_date = find('#transactions_created_at_gteq').value.to_date

          expect(start_date).to eq(Date.current)
        end
      end
    end

    describe 'filtering' do
      context 'by Transaction ID' do
        it 'is found' do
          transaction = EveryMatrix::Transaction.all.sample
          fill_in('Transaction ID', with: transaction.id)
          click_on('Search')

          within 'table.table.em_transactions tbody' do
            expect(page).to have_selector("tr#transaction-#{transaction.id}")
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'is not found' do
          fill_in('Transaction ID', with: -1)
          click_on('Search')

          within 'table.table.em_transactions tbody' do
            expect(page).to have_content(
              I18n.t(:not_found, instance: I18n.t('entities.transactions'))
            )
          end
        end
      end

      context 'by Type' do
        before do
          create(:every_matrix_transaction, :wager)
          create(:every_matrix_transaction, :result)
        end

        [EveryMatrix::Wager, EveryMatrix::Result].each do |type|
          it "is found #{type} results" do
            page.find('select#transactions_type_eq')
                .select(type.name.demodulize)

            click_on 'Search'

            within 'table.table.em_transactions tbody' do
              expect(transaction_ids(page).sort).to eq(type.ids.sort)
            end
          end
        end
      end
    end
  end
end
