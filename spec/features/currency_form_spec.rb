describe Currency, '#form' do
  context 'new currency form' do
    before do
      login_as create(:admin_user), scope: :user
      visit new_currency_path
    end

    it 'shows code validation error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :currency_code, with: ''
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    it 'shows name validation error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :currency_name, with: ''
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    it 'redirect to currency edit page on success' do
      fill_in :currency_code, with: 'COD'
      fill_in :currency_name, with: 'Test currency'
      EntryKinds::KINDS.keys.each.with_index do |_, index|
        fill_in "currency_entry_currency_rules_attributes_#{index}_min_amount",
                with: 10
        fill_in "currency_entry_currency_rules_attributes_#{index}_max_amount",
                with: 1000
      end
      click_submit

      currency = Currency.order(created_at: :desc).reload.first

      expect(page).to have_current_path(edit_currency_path(currency))
      expect(page).to have_content('COD')
    end
  end

  context 'existing label form' do
    let!(:existing_currency) do
      create(:currency, code: 'EUR')
    end

    before do
      login_as create(:user), scope: :user
      visit edit_currency_path(existing_currency)
    end

    it 'shows code validation error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :currency_code, with: ''
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    it 'shows name validation error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :currency_name, with: ''
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    # it 'shows amount validation error' do
    #   expect(page).not_to have_selector('.alert-danger')
    #   fill_in :currency_name, with: ''
    #   click_submit
    #   expect(page).to have_selector('.alert-danger')
    # end

    it 'shows amount amount error' do
      expect(page).not_to have_selector('.alert-danger')
      fill_in :currency_entry_currency_rules_attributes_0_min_amount, with: ''
      click_submit
      expect(page).to have_selector('.alert-danger')
    end

    it 'redirect to currency edit page on success' do
      fill_in :currency_name, with: 'New name'
      click_submit

      currency = Currency.order(created_at: :desc).reload.first

      expect(page).to have_current_path(edit_currency_path(currency))
      expect(page).to have_content(I18n.t('currencies.edit.title'))
    end
  end
end
