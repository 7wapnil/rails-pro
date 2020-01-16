# frozen_string_literal: true

# rubocop:disable RSpec/NestedGroups
describe Api::EveryMatrix::WalletsController, type: :controller do
  let!(:primary_currency) { create(:currency, :primary) }
  let(:em_login) { 'testlogin' }
  let(:em_password) { 'testpassword' }
  let(:em_operator_id) { 6 }

  let(:customer) { create(:customer, :with_address, :ready_to_bet) }
  let(:wallet) { customer.wallet }
  let(:currency_code) { wallet.currency.code }

  let(:default_country) { 'US' }

  let(:customer_session) do
    create(:wallet_session, wallet: wallet)
  end

  let(:common_request_params) do
    {
      'ApiVersion' => '1.0',
      'LoginName'  => em_login,
      'Password'   => em_password,
      'OperatorId' => em_operator_id
    }
  end

  let(:common_response) do
    {
      'ApiVersion' => '1.0',
      'Request'    => request_name
    }
  end

  let(:common_success_response) do
    common_response.merge(
      'ReturnCode' => 0,
      'Message'    => 'Success'
    )
  end

  let(:post_response) do
    post(:create, params: payload)

    response
  end

  let(:json) { JSON.parse(post_response.body) }

  before do
    Geocoder.configure(lookup: :test, ip_lookup: :test)
    Geocoder::Lookup::Test.set_default_stub([{ 'country' => default_country }])

    customer.address.update(country: 'United States of America')

    allow(ENV).to receive(:[]).and_call_original

    allow(ENV).to receive(:[])
      .with('EVERYMATRIX_WALLET_API_USERNAME')
      .and_return(em_login)

    allow(ENV).to receive(:[])
      .with('EVERYMATRIX_WALLET_API_PASSWORD')
      .and_return(em_password)
  end

  context 'without customer bonus' do
    let!(:balance_before) { wallet.real_money_balance }

    context 'GetAccount' do
      let(:request_name) { 'GetAccount' }

      context 'with existing session' do
        let(:country_code) do
          ISO3166::Country.find_country_by_name(customer.address.country).alpha3
        end

        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => customer_session.id
          )
        end

        let(:expected_response) do
          common_success_response.merge(
            'AccountId' => wallet.id.to_s,
            'Country'   => country_code,
            'Currency'  => currency_code,
            'SessionId' => customer_session.id,
            'UserName'  => customer.username,
            'City'      => customer.address.city,
            'FirstName' => customer.first_name,
            'LastName'  => customer.last_name,
            'Birthdate' => customer.date_of_birth.iso8601
          )
        end

        it 'successfully responds to request' do
          expect(json).to include(expected_response)
        end

        context 'with no current_sign_in_ip' do
          before do
            customer.update(current_sign_in_ip: nil)
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end
        end

        context 'with mBTC to BTC denomination' do
          before do
            wallet.currency.update_attribute(:code, 'mBTC')
          end

          let(:denominated_response) do
            expected_response.merge('Currency' => 'BTC')
          end

          it 'successfully responds to request' do
            expect(json).to include(denominated_response)
          end
        end
      end

      context 'with missing session' do
        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => 'non-existing-session'
          )
        end

        let(:expected_response) do
          common_response.merge(
            'ReturnCode' => 103,
            'Message'    => 'User not found'
          )
        end

        it 'responds with correct error code and message' do
          expect(json).to include(expected_response)
        end
      end
    end

    context 'GetBalance' do
      let(:request_name) { 'GetBalance' }

      context 'with existing session' do
        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => customer_session.id,
            'AccountId' => customer.id.to_s
          )
        end

        let(:expected_response) do
          common_success_response.merge(
            'Balance'    => wallet.real_money_balance.to_s,
            'Currency'   => currency_code,
            'SessionId'  => customer_session.id,
            'BonusMoney' => 0,
            'RealMoney'  => wallet.real_money_balance.to_s
          )
        end

        it 'successfully responds to request' do
          expect(json).to include(expected_response)
        end

        context 'with mBTC to BTC denomination' do
          before do
            wallet.currency.update_attribute(:code, 'mBTC')
          end

          let(:expected_bonus_money) do
            0
          end

          let(:expected_real_money) do
            (wallet.real_money_balance * 0.001).truncate(5).to_s
          end

          let(:expected_balance) do
            expected_real_money
          end

          let(:expected_response) do
            common_success_response.merge(
              'Balance'    => expected_balance,
              'Currency'   => 'BTC',
              'SessionId'  => customer_session.id,
              'BonusMoney' => expected_bonus_money,
              'RealMoney'  => expected_real_money
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end
        end
      end

      context 'with missing session' do
        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => 'non-existing-session'
          )
        end

        let(:expected_response) do
          common_response.merge(
            'ReturnCode' => 103,
            'Message'    => 'User not found'
          )
        end

        it 'responds with correct error code and message' do
          expect(json).to include(expected_response)
        end
      end
    end

    context 'Transactions' do
      let(:round_id) { Faker::Alphanumeric.alphanumeric }
      let(:transaction_id) { Faker::Number.number }
      let(:play_item) { create(:casino_game) }
      let(:payload) do
        common_request_params.merge(
          'Request'       => request_name,
          'SessionId'     => customer_session.id,
          'AccountId'     => customer.id.to_s,
          'Amount'        => amount,
          'TransactionId' => transaction_id,
          'RoundId'       => round_id,
          'GPGameId'      => play_item.game_code,
          'Device'        => 'desktop'
        )
      end

      context 'Wager' do
        let(:request_name) { 'Wager' }

        context 'with existing session' do
          let(:amount) { (wallet.real_money_balance / 2.0).round(2) }

          let!(:expected_response) do
            common_success_response.merge(
              'Balance'    => (balance_before - amount).to_d.to_s,
              'Currency'   => currency_code,
              'SessionId'  => customer_session.id
            )
          end

          before do
            allow(EveryMatrix::Requests::WagerSettlementService).to(
              receive(:call).and_return(true)
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end

          it 'triggers wager settlement service' do
            json

            expect(EveryMatrix::Requests::WagerSettlementService).to(
              have_received(:call)
            )
          end

          it 'is idempotent with same transaction_id' do
            first_json = json

            post(:create, params: payload)

            second_json = json

            expect(second_json).to eq(first_json)
          end

          it 'assigns correct play item to transaction' do
            json

            transaction =
              EveryMatrix::Transaction.find_by!(transaction_id: transaction_id)

            expect(transaction.play_item_id).to eq(play_item.id)
          end

          context 'with amount exceeding limit' do
            before do
              wallet.currency.entry_currency_rules.create!(
                kind: 'em_wager',
                min_amount: 0,
                max_amount: 0
              )
            end

            let(:expected_response) do
              common_response.merge(
                'ReturnCode' => 112,
                'Message'    => 'MaxStakeLimitExceeded'
              )
            end

            it 'responds with correct error code and message' do
              expect(json).to include(expected_response)
            end
          end

          context 'with mBTC to BTC denomination' do
            before do
              wallet.currency.update_attribute(:code, 'mBTC')
            end

            let(:amount) { wallet.real_money_balance * 0.001 / 2 }

            let(:expected_balance) do
              (balance_before * 0.001 - amount).to_d.truncate(5).to_s
            end

            let(:expected_response) do
              common_success_response.merge(
                'Balance'    => expected_balance,
                'Currency'   => 'BTC',
                'SessionId'  => customer_session.id
              )
            end

            it 'successfully responds to request' do
              expect(json).to include(expected_response)
            end
          end
        end

        context 'with existing session and insufficient funds' do
          let(:amount) { (balance_before * 2.0).round(2) }

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 104,
              'Message'    => 'Insufficient funds'
            )
          end

          it 'responds with insufficient funds error' do
            expect(json).to include(expected_response)
          end
        end

        context 'with missing session' do
          let(:payload) do
            common_request_params.merge(
              'Request'   => request_name,
              'SessionId' => 'non-existing-session'
            )
          end

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 103,
              'Message'    => 'User not found'
            )
          end

          it 'responds with correct error code and message' do
            expect(json).to include(expected_response)
          end
        end
      end

      context 'Result' do
        let(:request_name) { 'Result' }

        context 'with existing session' do
          let(:amount) { Faker::Number.decimal(4, 2).to_d }

          let(:expected_response) do
            common_success_response.merge(
              'Balance'    => (balance_before + amount).to_d.to_s,
              'Currency'   => currency_code,
              'SessionId'  => customer_session.id
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end

          it 'assigns correct play item to transaction' do
            json

            transaction =
              EveryMatrix::Transaction.find_by!(transaction_id: transaction_id)

            expect(transaction.play_item_id).to eq(play_item.id)
          end
        end

        context 'with missing session' do
          let(:payload) do
            common_request_params.merge(
              'Request'   => request_name,
              'SessionId' => 'non-existing-session'
            )
          end

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 103,
              'Message'    => 'User not found'
            )
          end

          it 'responds with correct error code and message' do
            expect(json).to include(expected_response)
          end
        end
      end

      context 'Rollback' do
        let(:request_name) { 'Rollback' }

        context 'with existing session' do
          let(:amount) { Faker::Number.decimal(4, 2).to_d }

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 108,
              'Message'    => 'TransactionNotFound'
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end

          it 'assigns correct play item to transaction' do
            json

            transaction =
              EveryMatrix::Transaction.find_by!(transaction_id: transaction_id)

            expect(transaction.play_item_id).to eq(play_item.id)
          end
        end

        context 'with missing session' do
          let(:payload) do
            common_request_params.merge(
              'Request'   => request_name,
              'SessionId' => 'non-existing-session'
            )
          end

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 103,
              'Message'    => 'User not found'
            )
          end

          it 'responds with correct error code and message' do
            expect(json).to include(expected_response)
          end
        end
      end
    end

    context 'GetTransactionStatus' do
      let(:request_name) { 'GetTransactionStatus' }
      let(:transaction_id) { Faker::Number.number }
      let(:payload) do
        common_request_params.merge(
          'Request' => request_name,
          'TransactionId' => transaction_id
        )
      end

      context 'with existing transaction' do
        let!(:transaction) do
          create(
            :every_matrix_transaction,
            transaction_id: transaction_id
          )
        end

        let(:expected_response) do
          common_success_response.merge(
            'TransactionId' => transaction_id,
            'TransactionStatus' => 'Processed'
          )
        end

        it 'responds with Processed status' do
          expect(json).to include(expected_response)
        end
      end

      context 'with missing transaction' do
        let(:expected_response) do
          common_success_response.merge(
            'TransactionId' => transaction_id,
            'TransactionStatus' => 'Notexists'
          )
        end

        it 'responds with Notexists status' do
          expect(json).to include(expected_response)
        end
      end
    end
  end

  context 'with customer bonus' do
    let!(:customer_bonus) do
      create(:customer_bonus, customer: customer, wallet: wallet, casino: true)
    end

    let!(:balance_before) { wallet.amount }

    context 'GetAccount' do
      let(:request_name) { 'GetAccount' }

      context 'with existing session' do
        let(:country_code) do
          ISO3166::Country.find_country_by_name(customer.address.country).alpha3
        end

        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => customer_session.id
          )
        end

        let(:expected_response) do
          common_success_response.merge(
            'AccountId' => wallet.id.to_s,
            'Country'   => country_code,
            'Currency'  => currency_code,
            'SessionId' => customer_session.id,
            'UserName'  => customer.username,
            'City'      => customer.address.city,
            'FirstName' => customer.first_name,
            'LastName'  => customer.last_name,
            'Birthdate' => customer.date_of_birth.iso8601
          )
        end

        it 'successfully responds to request' do
          expect(json).to include(expected_response)
        end

        context 'with mBTC to BTC denomination' do
          before do
            wallet.currency.update_attribute(:code, 'mBTC')
          end

          let(:denominated_response) do
            expected_response.merge('Currency' => 'BTC')
          end

          it 'successfully responds to request' do
            expect(json).to include(denominated_response)
          end
        end
      end

      context 'with missing session' do
        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => 'non-existing-session'
          )
        end

        let(:expected_response) do
          common_response.merge(
            'ReturnCode' => 103,
            'Message'    => 'User not found'
          )
        end

        it 'responds with correct error code and message' do
          expect(json).to include(expected_response)
        end
      end
    end

    context 'GetBalance' do
      let(:request_name) { 'GetBalance' }

      context 'with existing session' do
        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => customer_session.id,
            'AccountId' => customer.id.to_s
          )
        end

        let(:expected_response) do
          common_success_response.merge(
            'Balance'    => wallet.amount.to_s,
            'Currency'   => currency_code,
            'SessionId'  => customer_session.id,
            'BonusMoney' => wallet.bonus_balance.to_s,
            'RealMoney'  => wallet.real_money_balance.to_s
          )
        end

        it 'successfully responds to request' do
          expect(json).to include(expected_response)
        end

        context 'with mBTC to BTC denomination' do
          before do
            wallet.currency.update_attribute(:code, 'mBTC')
          end

          let(:expected_balance) do
            (wallet.amount * 0.001).truncate(5).to_s
          end

          let(:expected_bonus_money) do
            (wallet.bonus_balance * 0.001).truncate(5).to_s
          end

          let(:expected_real_money) do
            (wallet.real_money_balance * 0.001).truncate(5).to_s
          end

          let(:expected_response) do
            common_success_response.merge(
              'Balance'    => expected_balance,
              'Currency'   => 'BTC',
              'SessionId'  => customer_session.id,
              'BonusMoney' => expected_bonus_money,
              'RealMoney'  => expected_real_money
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end
        end
      end

      context 'with missing session' do
        let(:payload) do
          common_request_params.merge(
            'Request'   => request_name,
            'SessionId' => 'non-existing-session'
          )
        end

        let(:expected_response) do
          common_response.merge(
            'ReturnCode' => 103,
            'Message'    => 'User not found'
          )
        end

        it 'responds with correct error code and message' do
          expect(json).to include(expected_response)
        end
      end
    end

    context 'Transactions' do
      let(:round_id) { Faker::Alphanumeric.alphanumeric }
      let(:transaction_id) { Faker::Number.number }
      let(:play_item) { create(:casino_game) }
      let(:payload) do
        common_request_params.merge(
          'Request'       => request_name,
          'SessionId'     => customer_session.id,
          'AccountId'     => customer.id.to_s,
          'Amount'        => amount,
          'TransactionId' => transaction_id,
          'RoundId'       => round_id,
          'GPGameId'      => play_item.game_code,
          'Device'        => 'desktop'
        )
      end

      context 'Wager' do
        let(:request_name) { 'Wager' }

        context 'with existing session' do
          let(:amount) { (wallet.real_money_balance / 2.0).round(2) }

          let!(:expected_response) do
            common_success_response.merge(
              'Balance'    => (balance_before - amount).to_d.to_s,
              'Currency'   => currency_code,
              'SessionId'  => customer_session.id
            )
          end

          before do
            allow(EveryMatrix::Requests::WagerSettlementService).to(
              receive(:call).and_return(true)
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end

          it 'triggers wager settlement service' do
            json

            expect(EveryMatrix::Requests::WagerSettlementService).to(
              have_received(:call)
            )
          end

          it 'is idempotent with same transaction_id' do
            first_json = json

            post(:create, params: payload)

            second_json = json

            expect(second_json).to eq(first_json)
          end

          it 'assigns correct play item to transaction' do
            json

            transaction =
              EveryMatrix::Transaction.find_by!(transaction_id: transaction_id)

            expect(transaction.play_item_id).to eq(play_item.id)
          end

          context 'with amount exceeding limit' do
            before do
              wallet.currency.entry_currency_rules.create!(
                kind: 'em_wager',
                min_amount: 0,
                max_amount: 0
              )
            end

            let(:expected_response) do
              common_response.merge(
                'ReturnCode' => 112,
                'Message'    => 'MaxStakeLimitExceeded'
              )
            end

            it 'responds with correct error code and message' do
              expect(json).to include(expected_response)
            end
          end

          context 'with mBTC to BTC denomination' do
            before do
              wallet.currency.update_attribute(:code, 'mBTC')
            end

            let(:amount) { wallet.real_money_balance * 0.001 / 2 }

            let(:expected_balance) do
              (balance_before * 0.001 - amount).to_d.truncate(5).to_s
            end

            let(:expected_response) do
              common_success_response.merge(
                'Balance'    => expected_balance,
                'Currency'   => 'BTC',
                'SessionId'  => customer_session.id
              )
            end

            it 'successfully responds to request' do
              expect(json).to include(expected_response)
            end
          end
        end

        context 'with existing session and insufficient funds' do
          let(:amount) { (balance_before * 2.0).round(2) }

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 104,
              'Message'    => 'Insufficient funds'
            )
          end

          it 'responds with insufficient funds error' do
            expect(json).to include(expected_response)
          end
        end

        context 'with missing session' do
          let(:payload) do
            common_request_params.merge(
              'Request'   => request_name,
              'SessionId' => 'non-existing-session'
            )
          end

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 103,
              'Message'    => 'User not found'
            )
          end

          it 'responds with correct error code and message' do
            expect(json).to include(expected_response)
          end
        end
      end

      context 'Result' do
        let(:request_name) { 'Result' }

        context 'with existing session' do
          let(:amount) { Faker::Number.decimal(4, 2).to_d }

          let(:expected_response) do
            common_success_response.merge(
              'Balance'    => (balance_before + amount).to_d.to_s,
              'Currency'   => currency_code,
              'SessionId'  => customer_session.id
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end

          it 'assigns correct play item to transaction' do
            json

            transaction =
              EveryMatrix::Transaction.find_by!(transaction_id: transaction_id)

            expect(transaction.play_item_id).to eq(play_item.id)
          end
        end

        context 'with missing session' do
          let(:payload) do
            common_request_params.merge(
              'Request'   => request_name,
              'SessionId' => 'non-existing-session'
            )
          end

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 103,
              'Message'    => 'User not found'
            )
          end

          it 'responds with correct error code and message' do
            expect(json).to include(expected_response)
          end
        end
      end

      context 'Rollback' do
        let(:request_name) { 'Rollback' }

        context 'with existing session' do
          let(:amount) { Faker::Number.decimal(4, 2).to_d }

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 108,
              'Message'    => 'TransactionNotFound'
            )
          end

          it 'successfully responds to request' do
            expect(json).to include(expected_response)
          end

          it 'assigns correct play item to transaction' do
            json

            transaction =
              EveryMatrix::Transaction.find_by!(transaction_id: transaction_id)

            expect(transaction.play_item_id).to eq(play_item.id)
          end
        end

        context 'with missing session' do
          let(:payload) do
            common_request_params.merge(
              'Request'   => request_name,
              'SessionId' => 'non-existing-session'
            )
          end

          let(:expected_response) do
            common_response.merge(
              'ReturnCode' => 103,
              'Message'    => 'User not found'
            )
          end

          it 'responds with correct error code and message' do
            expect(json).to include(expected_response)
          end
        end
      end
    end

    context 'GetTransactionStatus' do
      let(:request_name) { 'GetTransactionStatus' }
      let(:transaction_id) { Faker::Number.number }
      let(:payload) do
        common_request_params.merge(
          'Request' => request_name,
          'TransactionId' => transaction_id
        )
      end

      context 'with existing transaction' do
        let!(:transaction) do
          create(
            :every_matrix_transaction,
            transaction_id: transaction_id
          )
        end

        let(:expected_response) do
          common_success_response.merge(
            'TransactionId' => transaction_id,
            'TransactionStatus' => 'Processed'
          )
        end

        it 'responds with Processed status' do
          expect(json).to include(expected_response)
        end
      end

      context 'with missing transaction' do
        let(:expected_response) do
          common_success_response.merge(
            'TransactionId' => transaction_id,
            'TransactionStatus' => 'Notexists'
          )
        end

        it 'responds with Notexists status' do
          expect(json).to include(expected_response)
        end
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
