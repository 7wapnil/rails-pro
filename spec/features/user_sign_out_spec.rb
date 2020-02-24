describe User, '#sign_out' do
  let!(:primary_currency) { create(:currency, :primary) }

  it 'Successfully signs out' do
    user = create(:admin_user)
    login_as user, scope: :user

    visit dashboard_path

    within 'nav.navbar' do
      click_link I18n.t(:sign_out)
    end

    expect(page).to have_current_path(new_user_session_path)
    expect_to_have_notification I18n.t('devise.sessions.signed_out')
  end
end
