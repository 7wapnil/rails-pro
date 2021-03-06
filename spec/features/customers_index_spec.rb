describe Customer, '#index' do
  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:customer, 5)

      login_as create(:admin_user), scope: :user
      visit customers_path
    end

    it 'shows customers list' do
      within 'table.table.entities' do
        Customer.limit(per_page_count).each do |customer|
          expect(page).to have_content(customer.username)
          expect(page).to have_content(customer.email)
          expect(page).to have_content(customer.last_sign_in_ip)
          expect(page).to have_content(customer.b_tag)
          expect(page).to have_content(customer.id)
        end
      end
    end

    it 'shows only not deleted customers in a list' do
      deleted_customers = create_list(:customer, 5, deleted_at: Date.new)

      within 'table.table.entities' do
        deleted_customers.each do |customer|
          expect(page).not_to have_content("#{customer.username} ")
          expect(page).not_to have_content(customer.email)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:customer, 10)
        visit customers_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    context 'search' do
      let!(:john) do
        create(:customer,
               username: 'john_doe',
               email: 'john_doe@email.com',
               b_tag: 'AFFTAGTEST')
      end

      it 'searches by username contains' do
        within 'table.search' do
          fill_in :customers_username_cont, with: 'john'
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.username)
        end
      end

      it 'searches by email contains' do
        within 'table.search' do
          fill_in :customers_email_cont, with: 'doe@email'
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.email)
        end
      end

      it 'searches by Btag contains' do
        within 'table.search' do
          fill_in :customers_b_tag_cont, with: 'afftag'
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.b_tag)
        end
      end

      it 'searches by last sign in ip address' do
        within 'table.search' do
          fill_in :customers_ip_address_eq, with: john.last_sign_in_ip
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.last_sign_in_ip)
        end
      end

      it 'searches by current sign in ip address' do
        within 'table.search' do
          fill_in :customers_ip_address_eq, with: john.current_sign_in_ip
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.last_sign_in_ip)
        end
      end

      it 'searches by id' do
        within 'table.search' do
          fill_in :customers_id_eq, with: john.id
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.id)
          expect(page).to have_content(john.username)
        end
      end

      it 'trims whitespaces from the query' do
        within 'table.search' do
          fill_in :customers_username_cont, with: '  john '
          click_submit
        end

        within 'table.entities > tbody' do
          expect(page).to have_content(john.username)
        end
      end
    end
  end
end
