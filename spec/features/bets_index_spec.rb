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
            rows = page.all('tr')
            bets_ids = rows.map do |row|
              row[:id].delete('bet-').to_i
            end
            sorted_ids = bets_ids.sort { |x, y| y <=> x }

            expect(bets_ids).to eq(sorted_ids)
          end
        end

        it 'in ASC direction' do
          click_link('Bet ID')
          within 'table.table.entities tbody' do
            rows = page.all('tr')
            bets_ids = rows.map do |row|
              row[:id].delete('bet-').to_i
            end
            sorted_ids = bets_ids.sort { |x, y| x <=> y }

            expect(bets_ids).to eq(sorted_ids)
          end
        end
      end

      context 'by dates interval' do
        it 'by default starts from today' do
          start_date = find('#bets_created_at_gteq').value.to_date

          expect(start_date).to eq(Time.zone.now.to_date)
        end
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

      context 'by Sport' do
        it 'found' do
          bet = Bet.first
          picked_sport = bet.title.external_name
          available_sports = page.find('#bets_title_external_name_eq')
                                 .all('option')
                                 .map(&:text)
                                 .reject(&:blank?)
          select picked_sport, from: 'Title External name equals'
          click_on('Search')

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet))
            expect(page).to have_content(bet.title.external_name)
            (available_sports - [picked_sport]).each do |sport|
              expect(page).not_to have_content(sport)
            end
          end
        end

        it 'not found' do
          bet = Bet.first
          picked_sport = bet.title.external_name
          Title.update_all(external_name: 'Dota2')
          select picked_sport, from: 'Title External name equals'
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

        it 'found' do
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

        it 'not found' do
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

      context 'by Category' do
        let(:france) { EventScope.find_by(name: 'France') }
        let(:pakistan) { EventScope.find_by(name: 'Pakistan') }
        let(:germany) { EventScope.find_by(name: 'Germany') }

        let(:bet_pakistan) { create(:bet) }
        let(:bet_france) { create(:bet) }
        let(:bet_germany) { create(:bet) }

        before do
          bet_pakistan.event.event_scopes << pakistan
          bet_france.event.event_scopes << france
          bet_germany.event.event_scopes << germany
        end

        it 'found by one category' do
          select pakistan.name, from: 'Event scope Name in'
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).to have_selector(resource_row_selector(bet_pakistan))
            expect(page).not_to have_selector(resource_row_selector(bet_france))
          end
        end

        it 'found by multiple categories' do
          dropdown = page.find('select#bets_categories_name_in')
          dropdown.select(pakistan.name)
          dropdown.select(france.name)
          click_on 'Search'

          within 'table.table.entities tbody' do
            bet_pakistan_selector = resource_row_selector(bet_pakistan)
            bet_france_selector = resource_row_selector(bet_france)
            bet_germany_selector = resource_row_selector(bet_germany)

            expect(page).not_to have_selector(bet_germany_selector)
            expect(page).to have_selector(bet_france_selector)
            expect(page).to have_selector(bet_pakistan_selector)
          end
        end

        it 'not found' do
          bet_france.event.event_scopes.delete_all
          select france.name, from: 'Event scope Name in'
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
