describe 'Customers#show' do
  subject { create(:customer) }

  context 'page content' do
    before do
      create_list(:currency, 3)

      login_as create(:admin_user), scope: :user
      visit customer_path(subject)
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

    it "shows 'Impersonate' link" do
      expect(page).to have_link('Impersonate')
    end

    it 'shows customer account type' do
      expect(page).to have_select('customer[account_kind]')
    end

    context 'account type transition' do
      let(:input_name) { 'customer[account_kind]' }
      it 'displays all possible types for regular customer' do
        all_options = Customer.account_kinds.keys

        expect(page).to have_select(input_name, options: all_options)
      end

      it 'displays allowed to transit account types' do
        subject.update_column(:account_kind, Customer.account_kinds[:staff])
        visit customer_path(subject)

        expect(page).to have_select(input_name, options: ['staff'])
      end
    end
  end

  context 'actions' do
    before do
      create(:address, customer: subject)
      login_as create(:admin_user), scope: :user
      visit customer_path(subject)
    end

    it 'updated personal information' do
      within 'form.personal-information-form' do
        fill_in :customer_first_name, with: 'Test'
        fill_in :customer_last_name, with: 'User'
        select 'Male', from: :customer_gender
        fill_in :customer_date_of_birth, with: '1 January 1990'
        click_submit
      end

      within '.container' do
        expect_to_have_notification I18n.t(
          :updated,
          instance: I18n.t('attributes.personal_information')
        )
      end
    end

    it 'updated contact information' do
      within 'form.contact-information-form' do
        fill_in :customer_email, with: 'test@test.com'
        fill_in :customer_phone, with: '+74951234567'
        fill_in :customer_address_attributes_street_address,
                with: 'Pushkina 1-1'
        fill_in :customer_address_attributes_zip_code, with: '101000'
        fill_in :customer_address_attributes_city, with: 'Moscow'
        fill_in :customer_address_attributes_state, with: 'Moscow'
        click_submit
      end

      within '.container' do
        expect_to_have_notification I18n.t(
          :updated,
          instance: I18n.t('attributes.contact_information')
        )
      end
    end
  end
end
