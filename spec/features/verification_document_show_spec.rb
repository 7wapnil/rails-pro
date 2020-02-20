describe VerificationDocument, '#show' do
  let!(:document) do
    create(:verification_document)
  end

  before do
    login_as create(:admin_user), scope: :user
    visit verification_documents_path
  end

  it 'shows document after click details' do
    within 'table.table.entities' do
      click_on(I18n.t('internal.details'))

      expect(page).to have_current_path(verification_document_path(document))
    end
  end

  it 'shows document page' do
    visit verification_document_path(document)

    expect_to_have_section('document-info')
    expect_to_have_section('comments')

    within 'table.table' do
      expect(page).to have_content(document.customer.username)
      expect(page)
        .to have_content(I18n.t("internal.attributes.#{document.kind}"))
      expect(page).to have_content(I18n.l(document.created_at, format: :long))
      expect(page).to have_content(document.status.capitalize)
      expect(page).to have_button(I18n.t('internal.action'))
      expect(page).to have_link(I18n.t('internal.view'))
    end
    expect(page).to have_content(I18n.t('internal.entities.comments'))
  end

  it 'shows action' do
    visit verification_document_path(document)

    within 'table.table' do
      expect(page).to have_button(I18n.t('internal.action'))
    end
  end

  it 'have comments' do
    visit verification_document_path(document)

    within '.comments' do
      # expect(page.has_field?(:text))
      expect(page).to have_button(I18n.t('internal.save'))
      fill_in('comment_text', with: 'test comment')
      click_submit
    end

    expect(page).to have_content('test comment')
    expect_to_have_notification(
      I18n.t('internal.created',
             instance: I18n.t('internal.attributes.comment'))
    )
  end
end
