shared_examples 'protected' do |protected_path_name|
  let(:protected_path) { send(protected_path_name) }

  it 'is protected' do
    visit protected_path

    expect(current_path).to eq new_user_session_path
    expect(page).to have_content I18n.t('devise.failure.unauthenticated')
  end
end
