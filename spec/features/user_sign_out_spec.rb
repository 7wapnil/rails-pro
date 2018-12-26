describe 'User Sign Out' do
  it 'Successfully signs out' do
    user = create(:admin_user)
    login_as user, scope: :user

    visit dashboard_path

    within 'nav.navbar' do
      click_link I18n.t(:sign_out)
    end

    expect(current_path).to eq new_user_session_path
    expect_to_have_notification I18n.t('devise.sessions.signed_out')
  end
end
