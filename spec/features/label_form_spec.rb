describe 'Label#form' do
  context 'new label form' do
    before do
      login_as create(:admin_user), scope: :user
      visit new_backoffice_label_path
    end

    it 'shows name validation error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :label_description, with: 'Label test description'
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    it 'redirect to labels list on success' do
      fill_in :label_name, with: 'LName'
      fill_in :label_description, with: 'Label test description'
      click_submit

      expect(page).to have_current_path(backoffice_labels_path)
      expect(page).to have_content('LName')
    end
  end

  context 'existing label form' do
    let!(:existing_label) do
      create(:label, name: 'VIP', description: 'Label for VIP users')
    end

    before do
      login_as create(:user), scope: :user
      visit edit_backoffice_label_path(existing_label)
    end

    it 'shows name validation error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :label_name, with: ''
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    it 'redirect to labels list on success' do
      fill_in :label_name, with: 'NewName'
      click_submit

      expect(page).to have_current_path(backoffice_labels_path)
      expect(page).to have_content('NewName')
    end
  end
end
