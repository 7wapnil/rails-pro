describe 'Customers#show' do
  subject { create(:customer) }

  context 'page content' do
    before do
      create_list(:currency, 3)

      login_as create(:admin_user), scope: :user
      visit backoffice_customer_path(subject)
    end

    it 'shows account information' do
      expect_to_have_section 'account-information'
    end

    it 'shows personal information' do
      expect_to_have_section 'personal-information'
    end

    it 'shows contact information' do
      expect_to_have_section 'contact-information'
    end
  end
end
