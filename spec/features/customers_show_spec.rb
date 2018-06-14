describe 'Customers#show' do
  subject { create(:customer) }

  context 'page content' do
    before do
      create_list(:currency, 3)

      login_as create(:admin_user), scope: :user
      visit backoffice_customer_path(subject)
    end

    it 'shows account information' do
      expect_to_have_section 'account-information'
    end

    it 'shows personal information' do
      expect_to_have_section 'personal-information'
    end

    it 'shows contact information' do
      expect_to_have_section 'contact-information'
    end

    context 'notes' do
      it 'shows customer notes section' do
        expect_to_have_section 'customer-notes'
      end

      it 'shows new note form' do
        within '.card.customer-notes' do
          expect(page).to have_selector 'form#new_customer_note'
        end
      end

      it 'creates customer note' do
        note_content = Faker::Lorem.paragraph

        within 'form#new_customer_note' do
          fill_in :customer_note_content, with: note_content
          click_submit
        end

        within '.card.customer-notes' do
          expect(page).to have_content note_content
        end
      end

      it 'fails to create empty customer note' do
        within 'form#new_customer_note' do
          click_submit
        end

        within '.container' do
          expect(page).to have_content(
            "#{I18n.t(:content)} #{I18n.t('errors.messages.blank')}"
          )
        end
      end
    end

    context 'balances' do
      it 'shows customers balance section' do
        expect_to_have_section 'balances'
      end

      it 'shows available balances' do
        create_list(:wallet, 3, customer: subject)

        visit backoffice_customer_path(subject)

        within '.balances' do
          subject.wallets.each do |wallet|
            expect(page).to have_content wallet.currency_name
            expect(page).to have_content wallet.amount
          end
        end
      end

      it 'shows no records note' do
        within '.balances' do
          expect(page).to have_content I18n.t(:no_records)
        end
      end
    end

    context 'activity' do
      it 'shows activity section' do
        expect_to_have_section 'activity'
      end

      it 'shows available entries' do
        wallet = create(:wallet, customer: subject)
        rule = create(:entry_currency_rule,
                      currency: wallet.currency,
                      min_amount: 10,
                      max_amount: 500)
        create_list(:entry, 10, wallet: wallet, kind: rule.kind, amount: 100)

        visit backoffice_customer_path(subject)

        within '.activity' do
          subject.entries.each do |entry|
            expect(page).to have_content entry.kind
            expect(page).to have_content entry.amount
            expect(page).to have_content entry.wallet.currency_code
          end
        end
      end

      it 'shows no records note' do
        expect(page).to have_content I18n.t(:no_records)
      end
    end

    context 'entry request' do
      it 'shows entry request form' do
        expect_to_have_section 'customer-entry-request'
      end

      it 'creates new customer entry request' do
        allow(EntryRequestProcessingJob).to receive(:perform_later)

        currency = create(:currency)
        create(:entry_currency_rule, currency: currency, kind: :deposit)

        visit backoffice_customer_path(subject)

        within 'form#new_entry_request' do
          select I18n.t('kinds.deposit'), from: :entry_request_kind
          fill_in :entry_request_amount, with: 200.00
          fill_in :entry_request_comment, with: 'A reason'
          click_submit
        end

        within '.container' do
          expect(page).to have_content(
            I18n.t(:created, instance: I18n.t('entities.entry_request'))
          )
        end
      end
    end

    def expect_to_have_section(section_class)
      within '.container' do
        expect(page).to have_selector ".card.#{section_class}"
      end
    end
  end
end
