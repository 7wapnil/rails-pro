describe VerificationDocument, '#index' do
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
        expect(page).to have_selector('.nav.nav-tabs#documents-tabs')
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
        click_on(I18n.t('navigation.document.recently_actioned'))

        within 'table.table.entities tbody' do
          expect(page).to have_selector("tr#document-#{rejected.id}")
          expect(page).to have_selector("tr#document-#{confirmed.id}")
          expect(page).to have_css('tr', count: 2)
        end
      end
    end

    describe 'sorting' do
      context 'by created_at' do
        let!(:doc_old) do
          create(:verification_document,
                 created_at: Time.zone.now.beginning_of_day)
        end

        let!(:doc) do
          create(:verification_document, created_at: Time.zone.now.end_of_day)
        end

        let(:link_title) { I18n.t('attributes.created_at') }
        let(:sort_link) { find_link(link_title) }

        it 'in asc direction' do
          sort_link.click if sort_in_desc_direction?(sort_link['href'])
          sort_link.click
          within 'table.table.entities tbody' do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end

            expect(document_ids).to eq([doc_old.id, doc.id])
          end
        end

        it 'in desc direction' do
          click_link(link_title) if sort_in_asc_direction?(sort_link['href'])
          click_link link_title
          within 'table.table.entities tbody' do
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
          within 'table.table.entities tbody' do
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

    describe 'filtering' do
      context 'by username' do
        let(:customer) { create(:customer) }
        let(:other_docs) { create_list(:verification_document, 3) }
        let!(:customer_docs) do
          create_list(:verification_document, 2, customer: customer)
        end

        it 'found' do
          fill_in(I18n.t('attributes.username'), with: customer.username)
          click_on 'Search'

          within 'table.table.entities tbody' do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end
            expect(document_ids).to match_array(customer_docs.map(&:id))
          end
        end

        it 'not found' do
          fill_in(I18n.t('attributes.username'), with: 'unknown_username')
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).not_to have_css('tr')
          end
        end
      end

      context 'by document type' do
        let!(:available_types) do
          page.find('#query_kind_eq')
              .all('option')
              .map(&:text)
              .reject(&:blank?)
        end

        let(:input_name) { 'Kind equals' }
        let!(:doc) { create(:verification_document, kind: :credit_card) }

        it 'found' do
          select doc.kind.humanize, from: input_name
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).to have_css("tr#document-#{doc.id}")
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'not found' do
          available_types.delete(doc.kind.humanize)
          option_name = available_types.first

          select option_name, from: input_name
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).not_to have_css('tr')
          end
        end
      end

      context 'by status' do
        let!(:rejected_doc) do
          create(:verification_document, status: :rejected)
        end

        let!(:confirmed_doc) do
          create(:verification_document, status: :confirmed)
        end

        let(:available_types) do
          page.find('#query_status_eq')
              .all('option')
              .map(&:text)
              .reject(&:blank?)
        end

        before { click_on I18n.t('navigation.document.recently_actioned') }

        it 'found' do
          select confirmed_doc.status.humanize, from: 'Status'
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).to have_css("tr#document-#{confirmed_doc.id}")
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'not found' do
          select rejected_doc.status.humanize, from: 'Status'
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).not_to have_css("tr#document-#{confirmed_doc.id}")
          end
        end
      end

      context 'by created_at dates range' do
        include_context 'frozen_time' do
          let(:frozen_time) { Time.zone.now }
        end

        let!(:old_doc) do
          create(:verification_document, created_at: Time.zone.now - 1.day)
        end

        let!(:future_doc) do
          create(:verification_document, created_at: Time.zone.now + 1.day)
        end

        let!(:today_doc) do
          create(:verification_document, created_at: Time.zone.now)
        end

        it 'by default has today date' do
          start_date = find('#query_created_at_gteq').value.to_date
          end_date = find('#query_created_at_lteq').value.to_date
          today = Time.zone.now.to_date

          expect(start_date).to eq(today)
          expect(end_date).to eq(today)
        end

        it 'found today docs' do
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).to have_css("tr#document-#{today_doc.id}")
            expect(page).to have_css('tr', count: 1)
          end
        end

        it 'found docs in dates range' do
          expected_documents_ids = [old_doc.id, future_doc.id, today_doc.id]

          fill_in 'Search From', with: old_doc.created_at.to_date
          fill_in 'Search To', with: future_doc.created_at.to_date
          click_on 'Search'

          within 'table.table.entities tbody' do
            document_ids = page.all('tr').map do |row|
              row[:id].delete('document-').to_i
            end
            expect(document_ids).to match_array(expected_documents_ids)
          end
        end

        it 'not found' do
          fill_in 'Search From', with: future_doc.created_at.to_date + 1.day
          click_on 'Search'

          within 'table.table.entities tbody' do
            expect(page).not_to have_css('tr')
          end
        end
      end
    end
  end
end
