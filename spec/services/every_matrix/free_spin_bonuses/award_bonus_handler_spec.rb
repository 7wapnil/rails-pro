# frozen_string_literal: true

describe EveryMatrix::FreeSpinBonuses::AwardBonusHandler do
  subject do
    described_class.call(free_spin_bonus_wallet: free_spin_bonus_wallet)
  end

  let(:request_regexp) do
    %r{http://vendorapi-stage.everymatrix.com/vendorbonus/.*/AwardBonus}
  end

  let(:response_headers) do
    { 'Content-Type' => 'application/json; charset=utf-8' }
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

  let(:free_spin_bonus_wallet) { create(:free_spin_bonus_wallet) }
  let(:success) { true }
  let(:response_body) { { Success: success }.to_json }

  before do
    allow(ENV).to receive(:[])
    env_variables.each_pair do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end

    allow(EveryMatrix::FreeSpinBonuses::CreateUserHandler)
      .to receive(:call)
      .and_return(true)

    stub_request(:post, request_regexp)
      .to_return(
        status: 200,
        headers: response_headers,
        body: response_body
      )
  end

  context 'without user_id' do
    before do
      free_spin_bonus_wallet
        .wallet
        .update_column(:every_matrix_user_id, nil)
    end

    it 'calls create user' do
      subject

      expect(EveryMatrix::FreeSpinBonuses::CreateUserHandler)
        .to have_received(:call)
    end
  end

  context 'with user_id' do
    before do
      free_spin_bonus_wallet
        .wallet
        .update_column(:every_matrix_user_id, 'em_user_id')
    end

    it 'does not call create user' do
      subject

      expect(EveryMatrix::FreeSpinBonuses::CreateUserHandler)
        .not_to have_received(:call)
    end

    context 'on success' do
      it 'changes status to awarded' do
        expect { subject }
          .to change(free_spin_bonus_wallet, :status)
          .from('initial')
          .to('awarded')
          .and change(free_spin_bonus_wallet, :last_request_name)
          .from(nil)
          .to('AwardBonus')
      end
    end

    context 'on error' do
      let(:success) { false }

      it 'changes status to awarded_with_error' do
        expect { subject }
          .to change(free_spin_bonus_wallet, :status)
          .from('initial')
          .to('awarded_with_error')
          .and change(free_spin_bonus_wallet, :last_request_name)
          .from(nil)
          .to('AwardBonus')
      end
    end
  end
end
