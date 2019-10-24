# frozen_string_literal: true

describe Webhooks::SafeCharge::PaymentsController, type: :controller do
  include_context 'safecharge_env'

  let(:params) { response.merge(advanceResponseChecksum: signature) }
  let(:signature) { Digest::SHA256.hexdigest(signature_string) }
  let(:signature_string) do
    [
      ENV['SAFECHARGE_SECRET_KEY'],
      *response.slice(*signature_keys).values
    ].join
  end
  let(:signature_keys) do
    %i[
      totalAmount
      currency
      responseTimeStamp
      PPP_TransactionID
      Status
      productId
    ]
  end

  let(:response) do
    {
      totalAmount: amount,
      currency: Faker::Currency.code,
      PPP_TransactionID: SecureRandom.hex(5),
      ppp_status: payment_status,
      Status: status,
      payment_method: payment_method,
      userPaymentOptionId: '2',
      request_id: entry_request.id,
      responseTimeStamp: Time.zone.now.to_s,
      productId: Faker::Number.number(5).to_s
    }
  end
  let(:amount) { Faker::Number.number(2).to_s }
  let(:payment_method) { Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER }
  let(:status) { Payments::Fiat::SafeCharge::Statuses::APPROVED }
  let(:payment_status) { Payments::Fiat::SafeCharge::Statuses::OK }

  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(:entry_request, amount: amount,
                           mode: mode,
                           customer: customer,
                           currency: currency,
                           origin: deposit)
  end
  let(:deposit) { create(:deposit) }
  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, currency: currency, customer: customer) }
  let(:entry) do
    create(:entry, kind: Entry::DEPOSIT, amount: amount, wallet: wallet)
  end
  let(:mode) { Payments::Methods::NETELLER }

  describe '#create' do
    subject { post(:create, params: params) }

    let(:payment_options_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/get_user_UPOs.json').read
      )
    end

    before do
      # ignore job after new customer creating
      allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
      allow(Customers::Summaries::BalanceUpdateWorker)
        .to receive(:perform_async)

      allow_any_instance_of(::Payments::Fiat::SafeCharge::Client)
        .to receive(:receive_user_payment_options)
        .and_return(payment_options_payload)
    end

    context 'when payment approved' do
      before { subject }

      it 'change deposit status to succeeded' do
        expect(deposit.reload.status).to eq(Deposit::SUCCEEDED)
      end

      it 'stores payment details' do
        subject
        expect(deposit.reload.details).to include(
          'user_payment_option_id' => '2',
          'name' => 'alex@kek.com'
        )
      end
    end

    context 'when payment failed' do
      let(:status) { Payments::Webhooks::Statuses::FAILED }
      let(:payment_status) { Payments::Webhooks::Statuses::FAILED }

      before do
        subject
      rescue Payments::TechnicalError => _e
      end

      it 'change deposit status to failed' do
        expect(deposit.reload.status).to eq(Deposit::FAILED)
      end
    end

    context 'when invalid signature' do
      let(:signature) { SecureRandom.hex(5) }

      it 'raise authentication error' do
        expect { subject }.to raise_error(Deposits::AuthenticationError)
      end

      it 'does not change deposit status' do
        subject
      rescue Deposits::AuthenticationError => _e
        expect(deposit.reload.status).to eq(Deposit::PENDING)
      end
    end
  end

  describe 'show' do
    subject { get(:show, params: params) }

    let(:frontend_url) { Faker::Internet.domain_name }
    let(:state) { :success }
    let(:message) do
      I18n.t('webhooks.safe_charge.redirections.success_message')
    end
    let(:query_params) do
      URI.encode_www_form(depositState: state, depositStateMessage: message)
    end
    let(:redirection_url) { "#{frontend_url}?#{query_params}" }

    before do
      allow(ENV)
        .to receive(:[])
        .with('FRONTEND_URL')
        .and_return(frontend_url)
    end

    context 'on OK transaction' do
      it 'redirects to success redirection url' do
        expect(subject).to redirect_to(redirection_url)
      end
    end

    context 'on SUCCESS transaction' do
      let(:payment_status) { ::Payments::Fiat::SafeCharge::Statuses::SUCCESS }

      it 'redirects to success redirection url' do
        expect(subject).to redirect_to(redirection_url)
      end
    end

    context 'on FAIL transaction' do
      let(:payment_status) { ::Payments::Fiat::SafeCharge::Statuses::FAIL }
      let(:state) { :fail }
      let(:message) { I18n.t('errors.messages.deposit_failed') }

      it 'redirects to error redirection url' do
        expect(subject).to redirect_to(redirection_url)
      end
    end

    context 'on transaction with unmapped status' do
      let(:payment_status) { 'TEST' }
      let(:state) { :fail }
      let(:message) { I18n.t('errors.messages.deposit_failed') }

      it 'redirects to error redirection url' do
        expect(subject).to redirect_to(redirection_url)
      end
    end

    context 'when invalid signature' do
      let(:signature) { SecureRandom.hex(5) }

      it 'raise authentication error' do
        expect { subject }.to raise_error(Deposits::AuthenticationError)
      end
    end
  end
end
