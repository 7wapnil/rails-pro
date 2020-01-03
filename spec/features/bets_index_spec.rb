describe Bet, '#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create(:event_scope, kind: EventScope::TOURNAMENT, name: 'X-Bet')
      create(:event_scope, kind: EventScope::TOURNAMENT, name: 'Crazy PANDAS')
      create(:event_scope, :category, name: 'Pakistan')
      create(:event_scope, :category, name: 'France')
      create(:event_scope, :category, name: 'Germany')
      create_list(:bet, per_page_count / 2)

      login_as create(:admin_user), scope: :user
      visit bets_path
    end

    it 'shows bets list' do
      within 'table.table.entities' do
        Bet.limit(per_page_count).each do |bet|
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
      it 'is shown' do
        create_list(:bet, per_page_count)
        visit bets_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    describe 'sorting' do
      context 'by ID' do
        it 'by default in DESC direction' do
          within 'table.table.entities tbody' do
            bets_ids = page.all('tr').map do |row|
              row[:id].delete('bet-').to_i
            end
            sorted_ids = bets_ids.sort { |x, y| y <=> x }

            expect(bets_ids).to eq(sorted_ids)
          end
        end

        it 'in ASC direction' do
          click_link('Bet ID')
          within 'table.table.entities tbody' do
            bets_ids = page.all('tr').map do |row|
              row[:id].delete('bet-').to_i
            end
            sorted_ids = bets_ids.sort { |x, y| x <=> y }

            expect(bets_ids).to eq(sorted_ids)
          end
        end
      end

      context 'by dates interval' do
        it 'by default has no start date' do
          start_date = find('#bets_created_at_gteq').value

          expect(start_date).to be_nil
        end
      end
    end

    describe 'filtering' do
      context 'by Bet ID' do
        it 'is found' do
          bet = Bet.all.sample
          fill_in('Bet ID', with: bet.id)
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet))
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'is not found' do
          fill_in('Bet ID', with: -1)
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_content(
              I18n.t(:not_found, instance: I18n.t('entities.bets'))
            )
          end
        end
      end

      context 'by Sport' do
        it 'is found' do
          bet = Bet.first
          picked_sport = bet.title.external_name
          available_sports = page.find('#bets_title_id_eq')
                                 .all('option')
                                 .map(&:text)
                                 .reject(&:blank?)
          select picked_sport, from: 'Title ID equals'
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet))
            expect(page).to have_content(bet.title.external_name)
            (available_sports - [picked_sport]).each do |sport|
              expect(page).not_to have_content(sport)
            end
          end
        end

        it 'is not found' do
          bet = Bet.first
          picked_sport = bet.title.decorate.name
          Bet.joins(:event).where(events: { title_id: bet.title.id }).delete_all
          select picked_sport, from: 'Title ID equals'
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_content(
              I18n.t(:not_found, instance: I18n.t('entities.bets'))
            )
          end
        end
      end

      context 'by Tournament' do
        let(:tournament) { EventScope.tournament.first }

        it 'is found' do
          bet = create(:bet)
          bet.event.event_scopes << tournament
          picked_tournament = tournament.name
          available_tournaments = page.find('#bets_tournaments_name_eq')
                                      .all('option')
                                      .map(&:text)
                                      .reject(&:blank?)
          select picked_tournament, from: 'Event scope Name equals'
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet))
            expect(page).to have_content(bet.title.name)
            (available_tournaments - [picked_tournament]).each do |tournament|
              expect(page).not_to have_content(tournament)
            end
          end
        end

        it 'is not found' do
          picked_tournament = tournament.name
          select picked_tournament, from: 'Event scope Name equals'
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_content(
              I18n.t(:not_found, instance: I18n.t('entities.bets'))
            )
          end
        end
      end

      context 'by status' do
        let!(:bet_cancelled) { create(:bet, :cancelled) }
        let!(:bet_settled) { create(:bet, :settled) }

        it 'found by one category' do
          select Bet::CANCELLED, from: 'Status eq'
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet_cancelled))
            expect(page)
              .not_to have_selector(resource_row_selector(bet_settled))
          end
        end

        it 'is not found' do
          select Bet::MANUALLY_SETTLED, from: 'Status eq'
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page)
              .to have_content(I18n.t(:not_found,
                                      instance: I18n.t('entities.bets')))
          end
        end
      end

      context 'by settlement status' do
        let!(:bet_lost) { create(:bet, :lost) }
        let!(:bet_won) { create(:bet, :won) }

        it 'found by one category' do
          select Bet::WON, from: 'Settlement status eq'
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet_won))
            expect(page).not_to have_selector(resource_row_selector(bet_lost))
          end
        end

        it 'is not found' do
          select Bet::VOIDED, from: 'Settlement status eq'
          click_on 'Search'

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
