describe 'Withdrawals index page' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      login_as create(:admin_user), scope: :user
    end

    it 'displays not found message' do
      not_found = I18n.t(:not_found, instance: I18n.t('entities.withdrawals'))
      visit withdrawals_path

      expect(page).to have_content(not_found)
    end

    context 'withdrawals table' do
      let!(:withdrawal) { create(:entry, kind: EntryRequest::WITHDRAW) }

      before do
        visit withdrawals_path
      end

      it 'displays withdrawals customer' do
        expect(page).to have_content(withdrawal.customer.username)
      end

      it 'displays wallet name' do
        wallet_name = I18n.t('entities.wallet_name',
                             currency: withdrawal.wallet.currency_name)

        expect(page).to have_content(wallet_name)
      end
    end

    context 'withdrawal confirmation' do
      before do
        create(:entry, kind: EntryRequest::WITHDRAW)
        visit withdrawals_path
      end

      it 'shows notification after withdrawal confirmation' do
        click_on I18n.t('confirm')

        expect_to_have_notification I18n.t('messages.withdrawal_confirmed')
      end
    end

    context 'withdrawal rejection' do
      before do
        create(:entry, kind: EntryRequest::WITHDRAW)
        visit withdrawals_path
      end

      it 'shows notification after withdrawal rejection' do
        fill_in 'Comment', with: 'Rejection reason'
        click_on I18n.t('reject')

        expect_to_have_notification I18n.t('messages.withdrawal_rejected')
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:entry, per_page_count + 1, kind: EntryRequest::WITHDRAW)
        visit withdrawals_path

        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        visit withdrawals_path

        expect(page).not_to have_selector('ul.pagination')
      end
    end
  end
end
