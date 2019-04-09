describe 'Withdrawals index page' do
  context 'signed in' do
    let(:per_page_count) { 10 }
    let(:passing_validator) do
      double('amount validator') # rubocop:disable RSpec/VerifiedDoubles
    end

    before do
      login_as create(:admin_user), scope: :user
      allow(passing_validator).to receive(:validate)
      allow(EntryAmountValidator).to receive(:new).and_return(passing_validator)
    end

    it 'displays not found message' do
      instance = I18n.t('entities.withdrawal_requests')
      not_found = I18n.t(:not_found, instance: instance)
      visit withdrawal_requests_path

      expect(page).to have_content(not_found)
    end

    context 'with pending withdrawal request table displays' do
      let(:withdrawal_request) { WithdrawalRequest.last }

      before do
        create(:withdrawal_request)
        visit withdrawal_requests_path
      end

      it 'customer' do
        username = withdrawal_request.entry_request.customer.username
        expect(page).to have_content(username)
      end

      it 'created_at timestamp' do
        expect(page).to have_content(withdrawal_request.created_at)
      end

      it 'amount' do
        expect(page).to have_content(withdrawal_request.entry_request.amount)
      end

      it 'currency' do
        currency_name = withdrawal_request.entry_request.currency.name
        expect(page).to have_content(currency_name)
      end

      it 'payment method' do
        expect(page).to have_content(withdrawal_request.entry_request.mode)
      end

      it 'status' do
        expect(page).to have_content(withdrawal_request.status)
      end
    end

    context 'withdrawal confirmation' do
      before do
        create(:withdrawal_request)
        visit withdrawal_requests_path
      end

      it 'shows notification after withdrawal confirmation' do
        click_on I18n.t('confirm')

        expect_to_have_notification I18n.t('messages.withdrawal_confirmed')
      end
    end

    context 'withdrawal rejection' do
      before do
        create(:withdrawal_request)
        visit withdrawal_requests_path
      end

      it 'shows notification after withdrawal rejection' do
        click_on I18n.t('reject')

        expect_to_have_notification I18n.t('messages.withdrawal_rejected')
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:withdrawal_request, per_page_count + 1)
        visit withdrawal_requests_path

        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        visit withdrawal_requests_path

        expect(page).not_to have_selector('ul.pagination')
      end
    end
  end
end
