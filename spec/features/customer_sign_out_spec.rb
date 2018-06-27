describe 'Customer Sign Out' do
  before(:context) { Capybara.app_host = 'http://arcanebet.test' }
  after(:context) { Capybara.app_host = nil }

  it 'Successfully signs out' do
    customer = create(:customer)
    login_as customer, scope: :customer

    visit root_path

    within 'nav.navbar' do
      click_link I18n.t(:sign_out)
    end

    expect_to_have_notification I18n.t('devise.sessions.signed_out')
  end
end
