describe 'Customers#notes' do
  let(:customer) { create(:customer) }
  let(:page_path) { notes_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  it 'shows customer notes section' do
    expect_to_have_section 'customer-notes'
  end

  it 'shows new note form' do
    within '.card.customer-note-form' do
      expect(page).to have_selector 'form#new_customer_note'
    end
  end

  it 'shows available notes' do
    create_list(:customer_note, 3, customer: customer)

    visit page_path

    within '.customer-notes' do
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

    within '.customer-notes' do
      deleted_notes.each do |note|
        expect(page).not_to have_content note.content
      end
    end
  end

  it 'shows no records note' do
    within '.customer-notes' do
      expect(page).to have_content I18n.t(:no_records)
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
      expect_to_have_notification(
        "#{I18n.t(:content)} #{I18n.t('errors.messages.blank')}"
      )
    end
  end
end
