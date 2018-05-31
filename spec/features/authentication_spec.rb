describe 'Authentication', type: :feature do
  context 'back office routes' do
    backoffice_get_paths = %i[backoffice_customers_path
                              backoffice_labels_path
                              new_backoffice_label_path]

    backoffice_get_paths.each do |path|
      it "#{path} is protected" do
        check_path_protection(path)
      end
    end

    it 'customer view is protected' do
      existing_customer = create(:customer)
      check_path_protection :backoffice_customer_path, existing_customer
    end

    it 'label edit form is protected' do
      existing_label = create(:label)
      check_path_protection :edit_backoffice_label_path, existing_label
    end

    def check_path_protection(protected_path_fn, instance = nil)
      visit send(protected_path_fn, instance)

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content I18n.t('devise.failure.unauthenticated')
    end
  end
end
