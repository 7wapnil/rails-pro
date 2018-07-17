describe 'Bonuses#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:bonus, 5)

      login_as create(:admin_user), scope: :user
      visit bonuses_path
    end

    it 'shows bonuses list' do
      within 'table.table' do
        Bonus.limit(per_page_count).each do |bonus|
          expect(page).to have_content(bonus.code)
        end
      end
    end

    it 'shows only not deleted bonuses in a list' do
      deleted_bonuses = create_list(:bonus, 5, deleted_at: Date.new)

      within 'table.table' do
        deleted_bonuses.each do |bonus|
          expect(page).not_to have_content(bonus.code)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:bonus, 10)
        visit bonuses_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    context 'search by code' do
      before do
        create :bonus, code: 'ARCANE100'
        create :bonus, code: 'WELCOME500'
        create :bonus, code: 'BETFORFREE'

        visit bonuses_path

        within 'form#bonus_search' do
          fill_in :query_code_cont, with: 'welcome'
          click_submit
        end
      end

      it 'finds bonus by code' do
        within 'table.table tbody' do
          expect(page).to have_content 'WELCOME500'
        end
      end

      it 'does not include bonus not matching search criteria' do
        within 'table.table tbody' do
          expect(page).not_to have_content 'ARCANE100'
          expect(page).not_to have_content 'BETFORFREE'
        end
      end
    end

    context 'filter by kind' do
      before do
        create :bonus, code: 'ARCANE100', kind: Bonus.kinds[:deposit]
        create :bonus, code: 'WELCOME500', kind: Bonus.kinds[:deposit]
        create :bonus, code: 'BETFORFREE', kind: Bonus.kinds[:free_bet]

        visit bonuses_path

        within 'form#bonus_search' do
          select :free_bet, from: :query_kind_eq
          click_submit
        end
      end

      it 'filters bonuses by kind' do
        within 'table.table tbody' do
          expect(page).to have_content 'BETFORFREE'
        end
      end

      it 'does not include bonus not matching filter criteria' do
        within 'table.table tbody' do
          expect(page).not_to have_content 'ARCANE100'
          expect(page).not_to have_content 'WELCOME500'
        end
      end

      it 'removes kind filter' do
        within 'form#bonus_search' do
          select '', from: :query_kind_eq
          click_submit
        end

        within 'table.table tbody' do
          expect(page).to have_content 'ARCANE100'
          expect(page).to have_content 'WELCOME500'
          expect(page).to have_content 'BETFORFREE'
        end
      end
    end

    context 'sorting' do
      before do
        create :bonus, code: 'ARCANE100', expires_at: Date.today.end_of_week
        create :bonus, code: 'WELCOME500', expires_at: Date.today.end_of_month
        create :bonus, code: 'BETFORFREE', expires_at: Date.today.end_of_year

        visit bonuses_path
      end

      it 'sorts by code' do
        within 'table.table thead' do
          click_on I18n.t('attributes.code')
        end

        first_row = all('table.table tbody tr').first
        last_row = all('table.table tbody tr').last

        expect(first_row).to have_content 'ARCANE100'
        expect(last_row).to have_content 'WELCOME500'
      end

      it 'sorts by expires_at' do
        within 'table.table thead' do
          click_on I18n.t('attributes.expires_at')
        end

        first_row = all('table.table tbody tr').first
        last_row = all('table.table tbody tr').last

        expect(first_row).to have_content 'ARCANE100'
        expect(last_row).to have_content 'BETFORFREE'
      end
    end
  end
end
