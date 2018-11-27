describe 'Documents#index' do
  context 'signed in' do
    let(:admin_user) { create(:user) }

    before do
      login_as create(:admin_user), scope: :user
      visit verification_documents_path
    end

    context 'navigation tabs' do
      let!(:pending) { create(:verification_document, status: :pending) }
      let!(:rejected) { create(:verification_document, status: :rejected) }
      let!(:confirmed) { create(:verification_document, status: :confirmed) }

      it 'displays nav tabs' do
        expect(page).to have_selector('.nav.nav-tabs#documents_tabs')
      end

      it 'by default displays pending documents' do
        visit  verification_documents_path

        within 'table.table.entities tbody' do
          expect(page).to have_selector("tr#document-#{pending.id}")
          expect(page).to have_css('tr', count: 1)
        end
      end

      it 'displays pending documents' do
        click_on(I18n.t('navigation.document.pending'))

        within 'table.table.entities tbody' do
          expect(page).to have_selector("tr#document-#{pending.id}")
          expect(page).to have_css('tr', count: 1)
        end
      end

      it 'displays recently auctioned' do
        click_on(I18n.t('navigation.document.recently_auctioned'))

        within 'table.table.entities tbody' do
          expect(page).to have_selector("tr#document-#{rejected.id}")
          expect(page).to have_selector("tr#document-#{confirmed.id}")
          expect(page).to have_css('tr', count: 2)
        end
      end
    end
  end
end
