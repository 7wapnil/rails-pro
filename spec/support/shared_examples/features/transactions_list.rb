shared_examples 'transactions list' do
  it 'shows transactions list' do
    within 'table.table.entities' do
      EntryRequest.transactions.limit(per_page_count).each do |entry_request|
        expect(page).to have_css('td.id > a', text: entry_request.id)
      end
    end
  end

  context 'searches by payment method' do
    it 'is found' do
      within 'table.search' do
        select EntryRequest::BITCOIN, from: :entry_requests_mode_eq
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).to have_css('td.id > a', text: the_transaction.id)
      end
    end

    it 'is not found' do
      within 'table.search' do
        select EntryRequest::CASHIER, from: :entry_requests_mode_eq
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).not_to have_css('td.id > a', text: the_transaction.id)
      end
    end
  end

  context 'searches by status' do
    it 'is found' do
      within 'table.search' do
        select EntryRequest::SUCCEEDED, from: :entry_requests_status_eq
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).to have_css('td.id > a', text: the_transaction.id)
      end
    end

    it 'is not found' do
      within 'table.search' do
        select EntryRequest::INITIAL, from: :entry_requests_status_eq
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).not_to have_css('td.id > a', text: the_transaction.id)
      end
    end
  end

  context 'searches by type' do
    it 'is found' do
      within 'table.search' do
        select EntryRequest::DEPOSIT.capitalize,
               from: :entry_requests_kind_eq
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).to have_css('td.id > a', text: the_transaction.id)
      end
    end

    it 'is not found' do
      within 'table.search' do
        select EntryRequest::WITHDRAW.capitalize,
               from: :entry_requests_kind_eq
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).not_to have_css('td.id > a', text: the_transaction.id)
      end
    end
  end

  context 'searches by date' do
    it 'is found' do
      within 'table.search' do
        fill_in :entry_requests_created_at_gteq,
                with: the_transaction.created_at
        fill_in :entry_requests_created_at_lteq,
                with: the_transaction.created_at + 1.day
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).to have_css('td.id > a', text: the_transaction.id)
      end
    end

    it 'is not found' do
      within 'table.search' do
        fill_in :entry_requests_created_at_gteq,
                with: the_transaction.created_at - 2.days
        fill_in :entry_requests_created_at_lteq,
                with: the_transaction.created_at - 1.day
        click_submit
      end

      within 'table.entities > tbody' do
        expect(page).not_to have_css('td.id > a', text: the_transaction.id)
      end
    end
  end
end
