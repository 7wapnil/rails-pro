# rubocop:disable FactoryBot/CreateList
describe Currency, '#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:currency, 5)

      login_as create(:admin_user), scope: :user
      visit currencies_path
    end

    it 'shows currencies list' do
      within 'table.table' do
        Currency.limit(per_page_count).each do |currency|
          expect(page).to have_content(currency.code)
          expect(page).to have_content(currency.name)
          expect(page).to have_content(currency.kind)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        10.times do |n|
          create(:currency, code: "XX#{n}")
        end
        visit currencies_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    context 'search' do
      let!(:euro) do
        create(:currency, code: 'PAB')
      end

      it 'searches by code contains' do
        within 'table' do
          fill_in :query_code_cont, with: 'pa'
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(euro.code)
        end
      end

      it 'searches by name contains' do
        within 'table' do
          fill_in :query_name_cont, with: 'ab cur'
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(euro.name)
        end
      end
    end
  end
end
# rubocop:enable FactoryBot/CreateList
