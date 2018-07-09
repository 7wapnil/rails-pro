describe 'Bonuses#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:bonus, 5)

      login_as create(:admin_user), scope: :user
      visit backoffice_bonuses_path
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
        visit backoffice_bonuses_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end
  end
end
