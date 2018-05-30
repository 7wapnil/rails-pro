require Rails.root.join('spec/features/shared_examples/protected')

describe 'Customers#index', type: :feature do

  it_behaves_like 'protected', :backoffice_customers_path

  context 'signed in' do
    let(:per_page_count) { 10 }

    before do
      create_list(:customer, 5)

      login_as create(:user), scope: :user
      visit backoffice_customers_path
    end

    it 'shows customers list' do
      within 'table.table' do
        Customer.limit(per_page_count).each do |customer|
          expect(page).to have_content(customer.username)
          expect(page).to have_content(customer.email)
          expect(page).to have_content(customer.last_sign_in_ip)
          expect(page).to have_content(customer.id)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:customer, 10)
        visit backoffice_customers_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    context 'search' do
      let!(:john) do
        create(:customer, username: 'john_doe', email: 'john_doe@email.com')
      end

      it 'searches by username contains' do
        within 'table' do
          fill_in :query_username_cont, with: 'john'
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(john.username)
        end
      end

      it 'searches by email contains' do
        within 'table' do
          fill_in :query_email_cont, with: 'doe@email'
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(john.email)
        end
      end

      it 'searches by last sign in ip address' do
        within 'table' do
          fill_in :query_ip_address_eq, with: john.last_sign_in_ip
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(john.last_sign_in_ip)
        end
      end

      it 'searches by current sign in ip address' do
        within 'table' do
          fill_in :query_ip_address_eq, with: john.current_sign_in_ip
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(john.last_sign_in_ip)
        end
      end

      it 'searches by id' do
        within 'table' do
          fill_in :query_id_eq, with: john.id
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(john.id)
          expect(page).to have_content(john.username)
        end
      end

      it 'trims whitespaces from the query' do
        within 'table' do
          fill_in :query_username_cont, with: 'j oh n '
          click_submit
        end

        within 'table > tbody' do
          expect(page).to have_content(john.username)
        end
      end
    end
  end
end
