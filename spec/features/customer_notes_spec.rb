describe Customer, '#notes' do
  let(:customer) { create(:customer) }

  before do
    login_as create(:admin_user), scope: :user
  end

  context 'with page' do
    let(:page_path) { notes_customer_path(customer) }

    before do
      visit page_path
    end

    it 'shows customer notes section' do
      expect(page).to have_selector '.customer-notes:not(.widget)'
    end

    it 'shows new note form' do
      within '.card.customer-note-form:not(.widget)' do
        expect(page).to have_selector 'form#new_customer_note:not(.widget)'
      end
    end

    it 'shows available notes' do
      create_list(:customer_note, 3, customer: customer)

      visit page_path

      within '.customer-notes:not(.widget)' do
        customer.customer_notes.each do |note|
          expect(page).to have_content note.content
          expect(page).to have_content note.user.full_name
        end
      end
    end

    it 'shows not deleted notes only' do
      deleted_notes = create_list(:customer_note,
                                  3,
                                  customer: customer,
                                  deleted_at: Date.new)

      visit page_path

      within '.customer-notes:not(.widget)' do
        deleted_notes.each do |note|
          expect(page).not_to have_content note.content
        end
      end
    end

    it 'shows no records note' do
      within '.customer-notes:not(.widget)' do
        expect(page).to have_content I18n.t(:no_records)
      end
    end

    it 'creates customer note' do
      note_content = Faker::Lorem.paragraph

      within 'form#new_customer_note:not(.widget)' do
        fill_in :customer_note_content, with: note_content
        click_submit
      end

      within '.customer-notes:not(.widget)' do
        expect(page).to have_content note_content
      end
    end

    it 'fails to create empty customer note' do
      within 'form#new_customer_note:not(.widget)' do
        click_submit
      end

      within '.container-fluid' do
        expect_to_have_notification(
          "#{I18n.t(:content)} #{I18n.t('errors.messages.blank')}"
        )
      end
    end
  end

  context 'with widget' do
    let(:page_path) { customer_path(customer) }

    before do
      visit page_path
    end

    it 'shows customer notes section' do
      expect(page).to have_selector '.customer-notes.widget'
    end

    it 'shows new note form' do
      within '.card.customer-note-form.widget' do
        expect(page).to have_selector 'form#new_customer_note.widget'
      end
    end

    it 'shows available notes' do
      create_list(:customer_note, 2, customer: customer)

      visit page_path

      within '.customer-notes.widget' do
        customer.customer_notes.each do |note|
          expect(page).to have_content note.content
          expect(page).to have_content note.user.full_name
        end
      end
    end

    it 'shows not deleted notes only' do
      deleted_notes = create_list(:customer_note,
                                  3,
                                  customer: customer,
                                  deleted_at: Date.new)

      visit page_path

      within '.customer-notes.widget' do
        deleted_notes.each do |note|
          expect(page).not_to have_content note.content
        end
      end
    end

    it 'shows no records note' do
      within '.customer-notes.widget' do
        expect(page).to have_content I18n.t(:no_records)
      end
    end

    it 'creates customer note' do
      note_content = Faker::Lorem.paragraph

      within 'form#new_customer_note.widget' do
        fill_in :customer_note_content, with: note_content
        click_submit
      end

      within '.customer-notes.widget' do
        expect(page).to have_content note_content
      end
    end

    it 'fails to create empty customer note' do
      within 'form#new_customer_note.widget' do
        click_submit
      end

      within '.container-fluid' do
        expect_to_have_notification(
          "#{I18n.t(:content)} #{I18n.t('errors.messages.blank')}"
        )
      end
    end
  end
end
