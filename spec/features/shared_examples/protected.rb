shared_examples 'protected' do |protected_path_name:, instance: false|
  let(:protected_path) do
    subject_id = instance ? subject.id : nil
    send(protected_path_name, subject_id)
  end

  it 'is protected' do
    visit protected_path

    expect(current_path).to eq new_user_session_path
    expect(page).to have_content I18n.t('devise.failure.unauthenticated')
  end
end
