describe 'Documents#show' do
  let!(:document) do
    create(:verification_document)
  end

  before do
    login_as create(:admin_user), scope: :user
    visit verification_documents_path
  end

  it 'shows document after click details' do
    within 'table.table.entities' do
      click_on(I18n.t('details'))

      expect(current_path).to eq(verification_document_path(document))
    end
  end

  it 'shows document page' do
    visit verification_document_path(document)

    expect_to_have_section('document-info')
    expect_to_have_section('comments')

    within 'table.table' do
      expect(page).to have_content(document.customer.username)
      expect(page).to have_content(I18n.t("attributes.#{document.kind}"))
      expect(page).to have_content(I18n.l(document.created_at, format: :long))
      expect(page).to have_content(I18n.t("statuses.#{document.status}"))
      expect(page).to have_button(I18n.t('action'))
      expect(page).to have_link(I18n.t('view'))
    end
    expect(page).to have_content(I18n.t('entities.comments'))
  end

  it 'shows action' do
    visit verification_document_path(document)

    within 'table.table' do
      expect(page).to have_button(I18n.t(:action))
    end
  end

  it 'have comments' do
    visit verification_document_path(document)

    within '.comments' do
      expect(page.has_field?(:text))
      expect(page).to have_button(I18n.t(:save))
      fill_in('comment_text', with: 'test comment')
      click_submit
    end

    expect(page).to have_content('test comment')
    expect_to_have_notification(I18n.t('created',
                                       instance: I18n.t('attributes.comment')))
  end
end
