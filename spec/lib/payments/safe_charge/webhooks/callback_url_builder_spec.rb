# frozen_string_literal: true

describe ::Payments::SafeCharge::Webhooks::CallbackUrlBuilder do
  subject { described_class.call(status: status) }

  let(:frontend_url) { Faker::Internet.url }
  let(:query_params) do
    URI.encode_www_form(
      depositState: state,
      depositStateMessage: message
    )
  end
  let(:expected_url) { URI("#{frontend_url}?#{query_params}").to_s }

  before do
    allow(ENV).to receive(:[])
      .with('FRONTEND_URL')
      .and_return(frontend_url)
  end

  context 'when success callback url requested' do
    let(:status) { ::Payments::PaymentResponse::STATUS_SUCCESS }
    let(:state) { :success }
    let(:message) do
      I18n.t('webhooks.safe_charge.redirections.success_message')
    end

    it 'generates correct url' do
      expect(subject).to eq(expected_url)
    end
  end

  context 'when cancellation callback url requested' do
    let(:status) { ::Payments::PaymentResponse::STATUS_CANCELLED }
    let(:state) { :error }
    let(:message) { I18n.t('errors.messages.deposit_request_cancelled') }

    it 'generates correct url' do
      expect(subject).to eq(expected_url)
    end
  end

  context 'when random callback url requested' do
    let(:status) { ::Payments::PaymentResponse::STATUS_PENDING }
    let(:state) {}
    let(:message) {}

    it 'generates url with empty fields' do
      expect(subject).to eq(expected_url)
    end
  end
end
