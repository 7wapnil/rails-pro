describe 'Withdrawals index page' do
  let(:per_page_count) { 10 }

  before do
    login_as create(:admin_user), scope: :user
    allow_any_instance_of(EntryAmountValidator).to receive(:validate)
  end

  it 'displays not found message' do
    instance = I18n.t('entities.withdrawals')
    not_found = I18n.t(:not_found, instance: instance)
    visit withdrawals_path

    expect(page).to have_content(not_found)
  end

  context 'with pending withdrawal request table displays' do
    let(:withdrawal) { Withdrawal.last }

    before do
      create(:withdrawal)
      visit withdrawals_path
    end

    it 'customer' do
      username = withdrawal.entry_request.customer.username
      expect(page).to have_content(username)
    end

    it 'created_at timestamp' do
      expect(page).to have_content(
        I18n.l(withdrawal.created_at, format: :long)
      )
    end

    it 'amount' do
      expect(page).to have_content(withdrawal.entry_request.amount)
    end

    it 'currency' do
      currency_name = withdrawal.entry_request.currency.name
      expect(page).to have_content(currency_name)
    end

    it 'payment method' do
      expect(page).to have_content(withdrawal.entry_request.mode)
    end

    it 'status' do
      expect(page).to have_content(withdrawal.status)
    end
  end

  context 'withdrawal confirmation' do
    before do
      create(:withdrawal)
      visit withdrawals_path
    end

    it 'shows notification after withdrawal confirmation' do
      click_on I18n.t('confirm')

      expect_to_have_notification I18n.t('messages.withdrawal_confirmed')
    end
  end

  context 'withdrawal rejection' do
    let(:message) { I18n.t('messages.withdrawal_rejected') }

    before do
      create(:withdrawal)
      visit withdrawals_path
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
        expect(Withdrawal.last.status).to eq Withdrawal::REJECTED
      end
    end

    context 'without comment' do
      before do
        click_on I18n.t('reject')
      end

      it 'keeps withdrawal request in pending status' do
        expect(Withdrawal.last.status).to eq Withdrawal::PENDING
      end
    end
  end

  context 'pagination' do
    it 'is shown' do
      create_list(:withdrawal, per_page_count + 1)
      visit withdrawals_path

      expect(page).to have_selector('ul.pagination')
    end

    it 'is hidden' do
      visit withdrawals_path

      expect(page).not_to have_selector('ul.pagination')
    end
  end

  context 'filtering' do
    context 'By withdrawal request ID' do
      let(:id_field) { 'withdrawals_id_eq' }

      it 'found' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        fill_in(id_field, with: withdrawal.id)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawals_path
        fill_in(id_field, with: -1)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawals'))
          )
        end
      end
    end

    context 'By status' do
      let(:status_drop_down) { 'withdrawals_status_eq' }

      it 'found' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        select Withdrawal::PENDING, from: status_drop_down
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawals_path
        select Withdrawal::REJECTED, from: status_drop_down
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawals'))
          )
        end
      end
    end

    context 'By creation timestamp' do
      let(:created_after) { 'withdrawals_created_at_gteq' }
      let(:created_before) { 'withdrawals_created_at_lteq' }

      it 'found by lower bound' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        lower_bound = withdrawal.created_at - 1.day
        fill_in(created_after, with: lower_bound)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'found by upper bound' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        upper_bound = withdrawal.created_at + 1.day
        fill_in(created_before, with: upper_bound)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        lower_bound = withdrawal.created_at + 1.day
        fill_in(created_after, with: lower_bound)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawals'))
          )
        end
      end
    end

    context 'By user actioned' do
      let(:actor_email) { 'withdrawals_actioned_by_email_cont' }
      let(:status_drop_down) { 'withdrawals_status_eq' }

      it 'found' do
        withdrawal = create(:withdrawal, :approved)
        visit withdrawals_path
        select Withdrawal::APPROVED, from: status_drop_down
        fill_in(actor_email, with: withdrawal.actioned_by.email)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawals_path
        fill_in(actor_email, with: Faker::Internet.email)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawals'))
          )
        end
      end
    end

    context 'By customer name' do
      let(:customer_name) do
        'withdrawals_entry_request_customer_username_cont'
      end

      it 'found' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        username = withdrawal.entry_request.customer.username
        fill_in(customer_name, with: username)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found' do
        visit withdrawals_path
        fill_in(customer_name, with: Faker::Lorem.word)
        click_on('Search')

        within 'table.table tbody' do
          expect(page).to have_content(
            I18n.t(:not_found, instance: I18n.t('entities.withdrawals'))
          )
        end
      end
    end

    context 'By payment method' do
      let(:payment_types) { 'withdrawals_entry_request_mode_eq' }

      it 'found by payment method' do
        withdrawal = create(:withdrawal)
        visit withdrawals_path
        select(withdrawal.entry_request.mode, from: payment_types)
        click_on('Search')

        within 'table.table tbody' do
          row_selector = resource_row_selector(withdrawal)
          expect(page).to have_selector(row_selector)
        end
      end

      it 'not found by payment method' do
        visit withdrawals_path
        select EntryRequest::BITCOIN, from: payment_types
        click_on('Search')

        within 'table.table tbody' do
          instance = I18n.t('entities.withdrawals')
          expect(page).to have_content(
            I18n.t(:not_found, instance: instance)
          )
        end
      end
    end
  end

  context 'sorting' do
    it 'sorts by created_at correctly' do
      withdrawals = create_list(:withdrawal, 3)
      withdrawals[0].update(created_at: 1.day.ago)
      withdrawals[1].update(created_at: 2.days.ago)
      visit withdrawals_path
      click_on('Created at')

      rows = page.all('table.table tr[id]')
      ids = rows.map { |row| row[:id].delete('withdrawal-').to_i }

      expected = withdrawals.sort_by(&:created_at).map(&:id)
      expect(ids).to eq(expected)
    end

    it 'sorts amount correctly' do
      requests = create_list(:withdrawal, 3)
      visit withdrawals_path
      click_on('Amount')

      rows = page.all('table.table tr[id]')
      ids = rows.map { |row| row[:id].delete('withdrawal-').to_i }

      expected = requests.sort_by { |wr| wr.entry_request.amount }
                         .map(&:id)

      expect(ids).to eq(expected)
    end
  end
end
