# frozen_string_literal: true

describe EveryMatrix::FreeSpinBonuses::CreateUserHandler do
  subject do
    described_class.call(free_spin_bonus_wallet: free_spin_bonus_wallet)
  end

  let(:request_url) do
    'http://guc-stage.everymatrix.com/userSession/generic/CreateUser'
  end

  let(:response_headers) do
    { 'Content-Type' => 'application/json; charset=utf-8' }
  end

  let(:response_body) do
    {
      Success: success,
      InternalUserId: every_matrix_user_id
    }.to_json
  end

  let(:env_variables) do
    {
      'EVERY_MATRIX_FREE_SPINS_URL' => 'http://vendorapi-stage.everymatrix.com',
      'EVERY_MATRIX_FREE_SPINS_LOGIN' => 'AnyLoginGoesOnStage',
      'EVERY_MATRIX_FREE_SPINS_PASSWORD' => 'AnyPasswordGoesOnStage',
      'EVERY_MATRIX_CREATE_USER_URL' =>
        'http://guc-stage.everymatrix.com/userSession/generic/CreateUser',
      'EVERY_MATRIX_DOMAIN_ID' => 2067
    }
  end

  let(:free_spin_bonus_wallet) do
    create(
      :free_spin_bonus_wallet,
      wallet: create(:customer, :ready_to_bet, :with_address).wallet
    )
  end

  let(:success) { true }
  let(:every_matrix_user_id) { nil }

  before do
    allow(ENV).to receive(:[])
    env_variables.each_pair do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end

    stub_request(:post, request_url)
      .to_return(
        status: 200,
        headers: response_headers,
        body: response_body
      )
  end

  context 'on success' do
    let(:every_matrix_user_id) { 'test_user_id' }

    it 'changes status to user_created and assigns every_matrix_user_id' do
      expect { subject }
        .to change(free_spin_bonus_wallet, :status)
        .from('initial')
        .to('user_created')
        .and change(free_spin_bonus_wallet, :last_request_name)
        .from(nil)
        .to('CreateUser')
        .and change(free_spin_bonus_wallet.wallet, :every_matrix_user_id)
        .from(nil)
        .to(every_matrix_user_id)
    end
  end

  context 'on error' do
    let(:success) { false }

    it 'changes status to user_created_with_error' do
      expect { subject }
        .to change(free_spin_bonus_wallet, :status)
        .from('initial')
        .to('user_created_with_error')
        .and change(free_spin_bonus_wallet, :last_request_name)
        .from(nil)
        .to('CreateUser')
    end
  end
end
