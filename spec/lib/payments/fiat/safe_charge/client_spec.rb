# frozen_string_literal: true

namespace = Payments::Fiat::SafeCharge

describe namespace::Client do
  include_context 'safecharge_env'

  let(:subject) { described_class.new(customer: customer) }

  let(:customer) { create(:customer) }
  let(:base_uri) { ENV['SAFECHARGE_URL'] }
  let(:headers) do
    { 'Content-Type': 'application/json', 'Accept': 'application/json' }
  end
  let(:response_status) { 200 }

  before do
    allow(namespace::RequestBuilders::ReceiveUserPaymentOptions)
      .to receive(:call)
      .with(customer: customer)
      .and_return(nil)

    stub_request(:post, "#{base_uri}/ppp/api/v1/getUserUPOs.do")
      .with(headers: headers, body: 'null')
      .to_return(status: response_status, body: body)
  end

  describe '#receive_user_payment_options' do
    context 'on valid payload' do
      let(:body) do
        file_fixture('payments/fiat/safe_charge/get_user_UPOs.json').read
      end

      let(:expected_payment_option_ids) do
        subject.receive_user_payment_options
               .map { |option| option['userPaymentOptionId'].to_i }
      end

      let(:control_payment_option) do
        subject.receive_user_payment_options
               .find { |option| option['userPaymentOptionId'].to_i == 2 }
      end

      it 'returns all payment options' do
        expect(expected_payment_option_ids).to match_array([1, 2, 3])
      end

      it 'returns payment option fields' do
        expect(control_payment_option).to include(
          'userPaymentOptionId' => 2,
          'upoData' => {
            'nettelerSecureId' => '123321',
            'nettelerAccount' => '1488228'
          }
        )
      end
    end

    context 'on error response' do
      let(:body) do
        file_fixture('payments/fiat/safe_charge/get_user_UPOs_error.json').read
      end

      it 'returns nothing' do
        expect(subject.receive_user_payment_options).to eq([])
      end
    end

    context 'on SafeCharge internal server error' do
      let(:body) do
        file_fixture(
          'payments/fiat/safe_charge/get_user_UPOs_internal_server_error.html'
        ).read
      end
      let(:response_status) { 415 }

      it 'returns nothing' do
        expect(subject.receive_user_payment_options).to eq([])
      end
    end
  end

  describe '#receive_user_payment_options' do
    context 'on valid payload' do
      let(:body) do
        file_fixture('payments/fiat/safe_charge/get_user_UPOs.json').read
      end

      it 'returns payment option fields on integer option id' do
        expect(subject.receive_user_payment_option(2)).to include(
          'userPaymentOptionId' => 2,
          'upoData' => {
            'nettelerSecureId' => '123321',
            'nettelerAccount' => '1488228'
          }
        )
      end

      it 'returns payment option fields on string option id' do
        expect(subject.receive_user_payment_option('1')).to include(
          'userPaymentOptionId' => 1,
          'upoData' => { 'account_id' => '322322322' }
        )
      end
    end

    context 'on error response' do
      let(:body) do
        file_fixture('payments/fiat/safe_charge/get_user_UPOs_error.json').read
      end

      it 'returns nothing' do
        expect(subject.receive_user_payment_option(2)).to eq({})
      end
    end

    context 'on SafeCharge internal server error' do
      let(:body) do
        file_fixture(
          'payments/fiat/safe_charge/get_user_UPOs_internal_server_error.html'
        ).read
      end
      let(:response_status) { 415 }

      it 'returns nothing' do
        expect(subject.receive_user_payment_option('1')).to eq({})
      end
    end
  end
end
