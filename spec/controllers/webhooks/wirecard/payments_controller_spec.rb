# frozen_string_literal: true

describe Webhooks::Wirecard::PaymentsController, type: :controller do
  include_context 'wirecard_env'

  subject do
    post(:create, params: params, body: body)
  end

  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(
      :entry_request,
      customer: customer,
      currency: currency,
      origin: origin
    )
  end
  let(:currency) { create(:currency, code: 'EUR') }
  let(:wallet) { create(:wallet, currency: currency) }
  let(:entry) do
    create(
      :entry,
      kind: kind,
      amount: amount,
      wallet: wallet,
      entry_request: entry_request
    )
  end

  let(:signature) do
    OpenSSL::HMAC.hexdigest(
      Payments::Fiat::Wirecard::SignatureVerifier::SIGNATURE_ALGORITHM,
      ENV['WIRECARD_SECRET_KEY'],
      signature_id.to_s
    )
  end
  let(:params) do
    {
      request_id: request_id,
      signature: signature
    }
  end
  let(:body) { '' }
  let(:request_id) { entry_request.id }
  let(:signature_id) { entry_request.id }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)

    # ignore GA event tracking
    # allow(GaEvents::SuccesfulPayment)
    #   .to receive(:call)
    #   .and_return(true)
  end

  context 'when withdrawal' do
    let(:kind) { Entry::WITHDRAW }
    let(:origin) { withdrawal }
    let(:withdrawal) do
      create(
        :withdrawal,
        status: CustomerTransaction::PROCESSING,
        entry_request: nil
      )
    end
    let(:body) do
      response.to_xml
    end
    let(:response) do
      Nokogiri::XML::Builder.new do |xml|
        xml.payment do
          xml.send(:'transaction-type', transaction_type)
          xml.send(:'transaction-state', state)
          xml.send(:'transaction-id', SecureRandom.hex(5))
          xml.send(:'request-id', "#{entry_request.id}:#{Time.zone.now}")
          xml.statuses do
            xml.status do
              xml.code code
              xml.description description
            end
          end
        end
      end
    end
    let(:transaction_type) do
      Payments::Fiat::Wirecard::CallbackHandler::WITHDRAWAL
    end

    context 'when success' do
      let(:code) { '201.0000' }
      let(:state) { Payments::Fiat::Wirecard::TransactionStates::SUCCESSFUL }
      let(:description) { 'Created' }

      it 'changes withdrawal status to succeeded' do
        subject

        expect(withdrawal.reload.status).to eq(Withdrawal::SUCCEEDED)
      end
    end

    context 'when failed' do
      let(:code) do
        Payments::Fiat::Wirecard::Statuses::CANCELLED_STATUSES.sample
      end
      let(:state) { Payments::Fiat::Wirecard::TransactionStates::FAILED }
      let(:description) { 'Failed' }

      it 'changes withdrawal status to pending' do
        subject

        expect(withdrawal.reload.status).to eq(Withdrawal::PENDING)
      end
    end

    context 'when invalid signature' do
      let(:signature_id) { -1 }
      let(:code) { '201.0000' }
      let(:state) { Payments::Fiat::Wirecard::TransactionStates::SUCCESSFUL }
      let(:description) { 'Created' }

      it 'keeps withdrawal status' do
        subject
      rescue Deposits::AuthenticationError => _e
        expect(withdrawal.reload.status).to eq(Withdrawal::PROCESSING)
      end
    end
  end

  context 'when deposit' do
    let(:kind) { Entry::DEPOSIT }
    let(:origin) { deposit }
    let(:deposit) do
      create(
        :deposit,
        status: CustomerTransaction::PENDING,
        entry_request: nil
      )
    end
    let(:params) do
      {
        'response-signature-base64' => base64_hmac,
        'response-base64' => base64_body,
        request_id: request_id,
        signature: signature
      }
    end
    let(:base64_body) { Base64.encode64(body.to_json) }
    let(:body) do
      {
        'payment' => {
          'statuses' => {
            'status' => [{
              'code' => code,
              'description' => description
            }]
          },
          'transaction-state' => state,
          'transaction-id' => SecureRandom.hex(5),
          'card-token' => {
            'token-id' => SecureRandom.hex(10),
            'masked-account-number' => SecureRandom.hex(10)
          },
          'account-holder' => {
            'first-name' => Faker::Name.first_name,
            'last-name' => Faker::Name.last_name
          },
          'request-id' => "#{entry_request.id}:#{Time.zone.now}",
          'transaction-type' => 'purchase'
        }
      }
    end
    let(:base64_hmac) { Base64.encode64(signature_hmac) }
    let(:signature_hmac) do
      OpenSSL::HMAC.digest(
        Payments::Fiat::Wirecard::SignatureVerifier::SIGNATURE_ALGORITHM,
        ENV['WIRECARD_SECRET_KEY'],
        base64_body
      )
    end

    context 'when success' do
      let(:code) { '201.0000' }
      let(:state) { Payments::Fiat::Wirecard::TransactionStates::SUCCESSFUL }
      let(:description) { 'Created' }

      before do
        allow(EntryRequests::DepositWorker).to receive(:perform_async)
      end

      it 'stores payment details' do
        subject

        expect(deposit.reload.details)
          .to include('masked_account_number', 'token_id')
      end
    end

    context 'when failed' do
      let(:code) { '422.0001' }
      let(:state) { Payments::Fiat::Wirecard::TransactionStates::FAILED }
      let(:description) { 'Failed' }

      before do
        allow(Payments::Webhooks::DepositRedirectionUrlBuilder)
          .to receive(:call)
          .and_call_original

        subject
      end

      it 'changes deposit status to failed' do
        expect(deposit.reload.status).to eq(Withdrawal::FAILED)
      end

      it 'does not pass any error message' do
        expect(Payments::Webhooks::DepositRedirectionUrlBuilder)
          .to have_received(:call)
          .with(status: state, custom_message: nil)
      end
    end

    context 'when invalid signature' do
      let(:signature_id) { -1 }
      let(:code) { '201.0000' }
      let(:state) { Payments::Fiat::Wirecard::TransactionStates::SUCCESSFUL }
      let(:description) { 'Created' }

      it 'keeps deposit status' do
        subject
      rescue Deposits::AuthenticationError => _e
        expect(deposit.reload.status).to eq(Withdrawal::PENDING)
      end
    end
  end
end
