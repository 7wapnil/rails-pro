describe Customer, '#activity' do
  let(:customer) { create(:customer) }
  let(:page_path) { activity_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  context 'activities' do
    it 'shows activities section' do
      expect_to_have_section 'audit-logs'
    end

    it 'shows no records note' do
      expect(page).to have_content I18n.t(:no_records)
    end
  end
end
