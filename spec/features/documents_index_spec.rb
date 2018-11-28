describe 'Documentss#index' do
  context 'signed in' do
    let(:admin_user) { create(:user) }

    before do
      login_as create(:admin_user), scope: :user
      visit documents_path
    end

    context 'navigation tabs' do
      let!(:pending) { create(:verification_document, status: :pending) }
      let!(:rejected) { create(:verification_document, status: :rejected) }
      let!(:confirmed) { create(:verification_document, status: :confirmed) }

      it 'displays nav tabs' do
        expect(page).to have_selector('.nav.nav-tabs#documents_tabs')
      end

      it 'by default displays pending documents' do
        visit documents_path

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

    describe 'sorting' do
      context 'by created_at' do
        let!(:doc_old) { create(:verification_document, created_at: 1.day.ago) }
        let!(:doc) { create(:verification_document) }
        let(:link_title) { I18n.t('attributes.created_at') }
        let(:sort_link) { find_link(link_title) }

        it 'in asc direction' do
          sort_link.click if sort_in_desc_direction?(sort_link['href'])
          sort_link.click
          within 'table.table.entities tbody'do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end

            expect(document_ids).to eq([doc_old.id, doc.id])
          end
        end

        it 'in desc direction' do
          click_link(link_title) if sort_in_asc_direction?(sort_link['href'])
          click_link link_title
          within 'table.table.entities tbody'do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end

            expect(document_ids).to eq([doc.id, doc_old.id])
          end
        end
      end

      context 'by username' do
        let(:first_doc) { create(:verification_document) }
        let(:last_doc) { create(:verification_document) }
        let(:link_title) { I18n.t('attributes.username') }
        let(:sort_link) { find_link(link_title) }

        before do
          first_doc.customer.update_column(:username, 'bar')
          last_doc.customer.update_column(:username, 'foo')
        end

        it 'in asc direction' do
          click_link(link_title) if sort_in_desc_direction?(sort_link['href'])
          click_link(link_title)
          within 'table.table.entities tbody'do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end
            expect(document_ids).to eq([first_doc.id, last_doc.id])
          end
        end

        it 'in desc direction' do
          click_link(link_title) if sort_in_asc_direction?(sort_link['href'])
          click_link(link_title)
          within 'table.table.entities tbody' do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end

            expect(document_ids).to eq([last_doc.id, first_doc.id])
          end
        end
      end
    end
  end
end
