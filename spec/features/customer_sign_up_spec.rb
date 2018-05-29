describe 'Customer Sign Up', type: :feature do
  before { visit new_customer_registration_path }

  let(:customer_attributes) do
    attributes_for(:customer).slice(
      :username,
      :email,
      :first_name,
      :last_name,
      :date_of_birth,
      :password
    )
  end

  it 'Successfully creates an account' do
    submit_customer_form_with customer_attributes

    expect(page).to have_content I18n.t('devise.registrations.signed_up')
    expect(current_path).to eq root_path
  end

  context 'Fails to create an account' do
    it 'username is already taken' do
      create(:customer, username: customer_attributes[:username])

      submit_customer_form_with(customer_attributes)

      expect(page).to have_content "Username #{I18n.t('errors.messages.taken')}"
    end

    it 'any of the required fields is missing' do
      missing_key = customer_attributes.keys.sample

      customer_attributes.delete(missing_key)

      submit_customer_form_with(customer_attributes)

      expect(page).to have_content(
        "#{missing_key.to_s.humanize} #{I18n.t('errors.messages.blank')}"
      )
    end

    it 'password is too short' do
      customer_attributes[:password] = 'short'

      submit_customer_form_with(customer_attributes)

      expect(page).to have_content(
        "Password #{I18n.t('errors.messages.too_short', count: 6)}"
      )
    end

    it 'password does not match confirmation' do
      customer_attributes[:password_confirmation] = 'doesntmatch'

      submit_customer_form_with(customer_attributes)

      expect(page).to have_content(
        "Password confirmation #{I18n.t('errors.messages.confirmation',
                                        attribute: 'Password')}"
      )
    end
  end
end

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def submit_customer_form_with(attributes)
  within 'form#new_customer' do
    fill_in 'customer_username', with: attributes[:username]
    fill_in 'customer_email', with: attributes[:email]
    fill_in 'customer_first_name', with: attributes[:first_name]
    fill_in 'customer_last_name', with: attributes[:last_name]

    if attributes[:date_of_birth]
      fill_in 'customer_date_of_birth', with: I18n.l(attributes[:date_of_birth])
    end

    fill_in 'customer_password', with: attributes[:password]

    fill_in 'customer_password_confirmation',
            with: attributes[:password_confirmation] || attributes[:password]

    click_submit
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
