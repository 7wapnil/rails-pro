describe Customer, '#update_lock' do
  let(:per_page_count) { 10 }

  context 'signed in' do
    let(:customer) { create(:customer) }
    let(:sample_lock_reason) do
      I18n.t("lock_reasons.#{Customer.lock_reasons.values.sample}")
      Customer.lock_reasons.values.sample
    end

    before do
      login_as create(:admin_user), scope: :user
      visit customer_path(customer)
    end

    it 'shows account lock block' do
      expect(page).to have_content(I18n.t('internal.attributes.account_lock'))
    end

    it 'lock customer' do
      within 'form#account_lock_form' do
        within '#customer_lock_reason' do
          find("option[value='#{sample_lock_reason}']").click
        end
        find('#customer_locked').check

        click_submit
      end
      expect(customer.reload.locked).to be(true)
    end
  end

  context 'when unlock customer' do
    let(:customer) { create(:customer, :locked) }

    before do
      login_as create(:admin_user), scope: :user
      visit customer_path(customer)
    end

    it 'unlock customer' do
      within 'form#account_lock_form' do
        select '', from: :customer_lock_reason
        find('#customer_locked').uncheck

        click_submit
      end
      expect(customer.reload.locked).to be(false)
    end
  end
end
