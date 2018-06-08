describe 'Customers#show' do
  subject { create(:customer) }

  context 'page content' do
    before do
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
      it 'displays customer notes section' do
        expect_to_have_section 'customer-notes'
      end

      it 'displays new note form' do
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

    context 'activity' do
      it 'shows activity section' do
        expect_to_have_section 'activity'
      end

      it 'shows available entries' do
        create_list(:entry, 10, wallet: create(:wallet, customer: subject))

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

    def expect_to_have_section(section_class)
      within '.container' do
        expect(page).to have_selector ".card.#{section_class}"
      end
    end
  end
end
