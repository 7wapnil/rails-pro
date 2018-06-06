describe 'Customer Sign Out' do
  it 'Successfully signs out' do
    customer = create(:customer)
    login_as customer, scope: :customer

    visit root_path

    within 'nav.navbar' do
      click_link I18n.t(:sign_out)
    end

    expect(page).to have_content I18n.t('devise.sessions.signed_out')
  end
end
