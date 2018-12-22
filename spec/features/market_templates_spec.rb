describe 'MarketTemplates#index' do
  let(:per_page_count) { 10 }

  before do
    create_list(:market_template, per_page_count / 2)

    login_as create(:admin_user), scope: :user
    visit market_templates_path
  end

  it 'shows market templates list' do
    within 'table.table.entities' do
      MarketTemplate.limit(per_page_count).each do |template|
        expect(page).to have_content(template.id)
        expect(page).to have_content(template.external_id)
        expect(page).to have_content(template.name)
        expect(page).to have_content(template.category)
      end
    end
  end

  context 'pagination' do
    it 'is shown' do
      create_list(:market_template, per_page_count)
      visit market_templates_path
      expect(page).to have_selector('ul.pagination')
    end

    it 'is hidden' do
      expect(page).not_to have_selector('ul.pagination')
    end
  end
end
