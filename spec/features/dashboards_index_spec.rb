describe 'Dashboards#index' do
  context 'signed in' do
    let(:bets_per_page_count) { DashboardsController::BETS_LIMIT }

    before do
      create(:event_scope, kind: EventScope::TOURNAMENT, name: 'X-Bet')
      create(:event_scope, kind: EventScope::TOURNAMENT, name: 'Crazy PANDAS')
      create(:event_scope_country, name: 'Pakistan')
      create(:event_scope_country, name: 'France')
      create(:event_scope_country, name: 'Germany')
      create_list(:bet, bets_per_page_count)

      login_as create(:admin_user), scope: :user
      visit dashboard_path
    end

    it 'shows bets list' do
      within 'table.table.entities' do
        Bet.limit(bets_per_page_count).each do |bet|
          expect(page).to have_content(bet.id)
          expect(page).to have_content(bet.customer.username)
          expect(page).to have_content(bet.odd.market.event.name)
          expect(page).to have_content(bet.odd.market.name)
          expect(page).to have_content(bet.odd.name)
          expect(page).to have_content(bet.odd_value)
          expect(page).to have_content(bet.amount)
        end
      end
    end

    context 'pagination' do
      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    describe 'filtering' do
      context 'by Bet ID' do
        it 'found' do
          bet = Bet.all.sample
          fill_in('Bet ID', with: bet.id)
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet))
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'not found' do
          fill_in('Bet ID', with: -1)
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_content(
              I18n.t(:not_found, instance: I18n.t('entities.bets'))
            )
          end
        end
      end

      context 'by Customer' do
        it 'found' do
          bet = Bet.all.sample
          fill_in('Customer', with: bet.customer.username)
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet))
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'not found' do
          fill_in('Customer', with: 'not valid username... at all')
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_content(
              I18n.t(:not_found, instance: I18n.t('entities.bets'))
            )
          end
        end
      end
    end
  end
end
