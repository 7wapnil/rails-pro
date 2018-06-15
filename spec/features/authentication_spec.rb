describe 'Authentication' do
  context 'back office routes' do
    context 'collection' do
      backoffice_collection_paths = %i[backoffice_customers_path
                                       backoffice_labels_path
                                       new_backoffice_label_path
                                       backoffice_entry_requests_path
                                       backoffice_root_path
                                       backoffice_dashboard_path]

      backoffice_collection_paths.each do |path|
        it "#{path} is protected" do
          check_path_protection(path)
        end
      end
    end

    context 'customer member' do
      let(:customer) { create(:customer) }

      customer_member_paths = %i[backoffice_customer_path
                                 activity_backoffice_customer_path
                                 notes_backoffice_customer_path]

      customer_member_paths.each do |path|
        it "#{path} is protected" do
          check_path_protection(path, customer)
        end
      end
    end

    context 'label member' do
      let(:label) { create(:label) }

      it 'edit_backoffice_label_path is protected' do
        check_path_protection :edit_backoffice_label_path, label
      end
    end

    context 'entry_request member' do
      let(:entry_request) { create(:entry_request) }

      it 'backoffice_entry_request_path is protected' do
        check_path_protection :backoffice_entry_request_path, entry_request
      end
    end

    def check_path_protection(protected_path_fn, instance = nil)
      visit send(protected_path_fn, instance)

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content I18n.t('devise.failure.unauthenticated')
    end
  end
end
