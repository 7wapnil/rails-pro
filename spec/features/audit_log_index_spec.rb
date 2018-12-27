describe AuditLog, '#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }
    let!(:current_user) { create(:admin_user) }
    let!(:customer) { create(:customer) }

    before do
      create_list(
        :audit_log,
        per_page_count / 2,
        user_id: current_user.id,
        customer_id: customer.id
      )

      login_as current_user, scope: :user
      visit activities_path
    end

    it 'shows activities list' do
      within 'table.table.activities' do
        AuditLog.limit(per_page_count).each do |activity|
          expect(page).to have_content(
            I18n.l(activity.created_at, format: :long)
          )
          expect(page).to have_content(
            I18n.t("events.#{activity.event}", activity.interpolation)
          )
        end
      end
    end

    context 'pagination' do
      context 'with more than per page activities' do
        before do
          create_list(
            :audit_log,
            per_page_count,
            user_id: current_user.id,
            customer_id: customer.id
          )
          visit activities_path
        end

        it 'is shown' do
          expect(page).to have_selector('ul.pagination')
        end
      end

      context 'with less than per page activities' do
        it 'is hidden' do
          expect(page).not_to have_selector('ul.pagination')
        end
      end
    end
  end
end
