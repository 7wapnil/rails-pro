describe 'Withdrawals index page' do
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
      expect(page).to have_content(
        I18n.l(withdrawal_request.created_at, format: :long)
      )
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
    let(:message) { I18n.t('messages.withdrawal_rejected') }

    before do
      create(:withdrawal_request)
      visit withdrawal_requests_path
    end

    context 'with comment' do
      before do
        page.find('#rejection_comment').fill_in(with: Faker::Lorem.word)
        click_on I18n.t('reject')
      end

      it 'shows notification after withdrawal rejection' do
        expect_to_have_notification message
      end

      it 'rejects withdrawal reqeust' do
        expect(WithdrawalRequest.last.status).to eq WithdrawalRequest::REJECTED
      end
    end

    context 'without comment' do
      before do
        click_on I18n.t('reject')
      end

      it 'keeps withdrawal request in pending status' do
        expect(WithdrawalRequest.last.status).to eq WithdrawalRequest::PENDING
      end
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

  context 'filtering' do
    context 'By withdrawal request ID' do
      let(:id_field) { 'withdrawal_requests_id_eq' }

      it 'found' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        fill_in(id_field, with: withdrawal_request.id)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawal_requests_path
        fill_in(id_field, with: -1)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawal_requests'))
          )
        end
      end
    end

    context 'By status' do
      let(:status_drop_down) { 'withdrawal_requests_status_eq' }

      it 'found' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        select WithdrawalRequest::PENDING, from: status_drop_down
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawal_requests_path
        select WithdrawalRequest::REJECTED, from: status_drop_down
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawal_requests'))
          )
        end
      end
    end

    context 'By creation timestamp' do
      let(:created_after) { 'withdrawal_requests_created_at_gteq' }
      let(:created_before) { 'withdrawal_requests_created_at_lteq' }

      it 'found by lower bound' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        lower_bound = withdrawal_request.created_at - 1.day
        fill_in(created_after, with: lower_bound)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'found by upper bound' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        upper_bound = withdrawal_request.created_at + 1.day
        fill_in(created_before, with: upper_bound)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        lower_bound = withdrawal_request.created_at + 1.day
        fill_in(created_after, with: lower_bound)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawal_requests'))
          )
        end
      end
    end

    context 'By user actioned' do
      let(:actor_email) { 'withdrawal_requests_actioned_by_email_cont' }
      let(:status_drop_down) { 'withdrawal_requests_status_eq' }

      it 'found' do
        withdrawal_request = create(:withdrawal_request, :approved)
        visit withdrawal_requests_path
        select WithdrawalRequest::APPROVED, from: status_drop_down
        fill_in(actor_email, with: withdrawal_request.actioned_by.email)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawal_requests_path
        fill_in(actor_email, with: Faker::Internet.email)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawal_requests'))
          )
        end
      end
    end

    context 'By customer name' do
      let(:customer_name) do
        'withdrawal_requests_entry_request_customer_username_cont'
      end

      it 'found' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        username = withdrawal_request.entry_request.customer.username
        fill_in(customer_name, with: username)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawal_requests_path
        fill_in(customer_name, with: Faker::Lorem.word)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawal_requests'))
          )
        end
      end
    end

    context 'By payment method' do
      let(:payment_types) { 'withdrawal_requests_entry_request_mode_eq' }

      it 'found by payment method' do
        withdrawal_request = create(:withdrawal_request)
        visit withdrawal_requests_path
        select(withdrawal_request.entry_request.mode, from: payment_types)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal_request)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found by payment method' do
        visit withdrawal_requests_path
        select EntryRequest::BITCOIN, from: payment_types
        click_on('Search')

        within 'table.table tbody' do
          instance = I18n.t('entities.withdrawal_requests')
          expect(page).to have_content(
            I18n.t(:not_found, instance: instance)
          )
        end
      end
    end
  end

  context 'sorting' do
    it 'sorts by created_at correctly' do
      withdrawal_requests = create_list(:withdrawal_request, 3)
      withdrawal_requests[0].update(created_at: 1.day.ago)
      withdrawal_requests[1].update(created_at: 2.days.ago)
      visit withdrawal_requests_path
      click_on('Created at')

      rows = page.all('table.table tr[id]')
      ids = rows.map { |row| row[:id].delete('withdrawalrequest-').to_i }

      expected = withdrawal_requests.sort_by(&:created_at).map(&:id)
      expect(ids).to eq(expected)
    end

    it 'sorts amount correctly' do
      requests = create_list(:withdrawal_request, 3)
      visit withdrawal_requests_path
      click_on('Amount')

      rows = page.all('table.table tr[id]')
      ids = rows.map { |row| row[:id].delete('withdrawalrequest-').to_i }

      expected = requests.sort_by { |wr| wr.entry_request.amount }
                         .map(&:id)

      expect(ids).to eq(expected)
    end
  end
end
