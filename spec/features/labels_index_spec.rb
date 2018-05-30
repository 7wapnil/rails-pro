describe 'Labels#index', type: :feature do
  it 'is protected' do
    visit backoffice_labels_path

    expect(current_path).to eq new_user_session_path
    expect(page).to have_content I18n.t('devise.failure.unauthenticated')
  end

  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:label, 5)

      login_as create(:user), scope: :user
      visit backoffice_labels_path
    end

    it 'shows labels list' do
      within 'table.table' do
        Label.limit(per_page_count).each do |label|
          expect(page).to have_content(label.name)
          expect(page).to have_content(label.description)
        end
      end
    end

    context 'search' do
      let!(:vip_label) do
        create(:label, name: 'VIP', description: 'Label for VIP users')
      end

      it 'searches by name contains' do
        within 'table' do
          fill_in :query_name_cont, with: 'vi'
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(vip_label.name)
        end
      end

      it 'searches by description contains' do
        within 'table' do
          fill_in :query_description_cont, with: 'vip'
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(vip_label.description)
        end
      end
    end
  end
end
