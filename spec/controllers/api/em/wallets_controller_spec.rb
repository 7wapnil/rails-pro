# frozen_string_literal: true

describe Api::Em::WalletsController, type: :controller do
  let!(:primary_currency) { create(:currency, :primary) }
  let(:em_login) { 'testlogin' }
  let(:em_password) { 'testpassword' }
  let(:em_operator_id) { 6 }

  let(:customer) { create(:customer, :with_address, :ready_to_bet) }
  let(:wallet) { customer.wallet }
  let(:currency_code) { wallet.currency.code }
  let!(:balance_before) { wallet.amount }

  let(:customer_session) do
    create(:em_wallet_session, wallet: wallet)
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

  let(:json) { JSON.parse(response.body) }

  before do
    allow(ENV).to receive(:fetch)
      .with('EVERYMATRIX_WALLET_API_USERNAME')
      .and_return(em_login)

    allow(ENV).to receive(:fetch)
      .with('EVERYMATRIX_WALLET_API_PASSWORD')
      .and_return(em_password)

    post(:create, params: payload)
  end

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
          'AccountId' => customer.id.to_s,
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

  context 'Wager' do
    let(:request_name) { 'Wager' }

    context 'with existing session' do
      let(:amount) { (balance_before / 2.0).round(2) }
      let(:transaction_id) { 123_456_789 }

      let(:payload) do
        common_request_params.merge(
          'Request'   => request_name,
          'SessionId' => customer_session.id,
          'AccountId' => customer.id.to_s,
          'Amount'    => amount,
          'TransactionId' => transaction_id
        )
      end

      let!(:expected_response) do
        common_success_response.merge(
          'Balance'    => (balance_before - amount).to_d.to_s,
          'Currency'   => currency_code,
          'SessionId'  => customer_session.id
        )
      end

      it 'successfully responds to request' do
        expect(json).to include(expected_response)
      end
    end

    context 'with existing session and insufficient funds' do
      let(:amount) { (balance_before * 2.0).round(2) }
      let(:transaction_id) { 123_456_789 }

      let(:payload) do
        common_request_params.merge(
          'Request'   => request_name,
          'SessionId' => customer_session.id,
          'AccountId' => customer.id.to_s,
          'Amount'    => amount,
          'TransactionId' => transaction_id
        )
      end

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
      let(:transaction_id) { 123_456_789 }

      let(:payload) do
        common_request_params.merge(
          'Request'   => request_name,
          'SessionId' => customer_session.id,
          'AccountId' => customer.id.to_s,
          'Amount'    => amount,
          'TransactionId' => transaction_id
        )
      end

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
      let(:transaction_id) { 123_456_789 }

      let(:payload) do
        common_request_params.merge(
          'Request'   => request_name,
          'SessionId' => customer_session.id,
          'AccountId' => customer.id.to_s,
          'Amount'    => amount,
          'TransactionId' => transaction_id
        )
      end

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
