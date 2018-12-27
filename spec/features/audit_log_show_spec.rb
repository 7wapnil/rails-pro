describe AuditLog, '#show' do
  include ActionView::Helpers::NumberHelper
  let!(:current_user) { create(:admin_user) }
  let!(:customer) { create(:customer) }

  context 'page content' do
    context 'with event context' do
      let(:subject) do
        create(:audit_log, user_id: current_user.id, customer_id: customer.id)
      end

      before do
        login_as current_user, scope: :user
        visit activity_path(subject)
      end

      it 'shows activity details with context' do
        expect(page).to have_content(
          I18n.t("events.#{subject.event}", subject.interpolation)
        )
        expect(page).to have_content(I18n.l(subject.created_at, format: :long))
        expect(page).to have_content(current_user.full_name)
        expect(page).to have_content(subject.context.content)
      end
    end

    context 'without event context' do
      let(:subject) do
        create(
          :audit_log,
          user_id: current_user.id,
          customer_id: customer.id,
          context: nil
        )
      end

      before do
        login_as current_user, scope: :user
        visit activity_path(subject)
      end

      it 'shows activity details without context' do
        expect(page).to have_content(
          I18n.t("events.#{subject.event}", subject.interpolation)
        )
        expect(page).to have_content(I18n.l(subject.created_at, format: :long))
        expect(page).to have_content(current_user.full_name)
        expect(page).not_to have_content(I18n.t('attributes.info'))
      end
    end
  end
end
