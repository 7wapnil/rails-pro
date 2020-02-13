# frozen_string_literal: true

describe ::Payments::Webhooks::DepositRedirectionUrlBuilder do
  subject { described_class.call(**params) }

  let(:params) { { status: status, request_id: entry_request.id } }

  let(:entry_request) { create(:entry_request, :deposit) }
  let(:frontend_url) { Faker::Internet.url }
  let(:query_params) do
    URI.encode_www_form(
      depositState: state,
      depositStateMessage: message,
      depositDetails: base_64_deposit_summary
    )
  end
  let(:base_64_deposit_summary) do
    Base64.encode64(URI.encode_www_form(deposit_summary))
  end
  let(:deposit_summary) do
    {
      realMoneyAmount: entry_request.real_money_amount,
      bonusAmount: entry_request.bonus_amount,
      paymentMethod: entry_request.mode,
      currencyCode: entry_request.currency&.code
    }
  end
  let(:expected_url) { URI("#{frontend_url}?#{query_params}").to_s }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[])
      .with('FRONTEND_URL')
      .and_return(frontend_url)
  end

  context 'when success callback url requested' do
    let(:status) { ::Payments::Webhooks::Statuses::SUCCESS }
    let(:state) { :success }
    let(:message) { I18n.t('messages.success_deposit') }

    it 'generates correct url' do
      expect(subject).to eq(expected_url)
    end
  end

  context 'when cancellation callback url requested' do
    let(:status) { ::Payments::Webhooks::Statuses::CANCELLED }
    let(:state) { :error }
    let(:message) { I18n.t('errors.messages.deposit_cancelled') }

    it 'generates correct url' do
      expect(subject).to eq(expected_url)
    end
  end

  context 'when random callback url requested' do
    let(:status) { 'pending' }
    let(:state) {}
    let(:message) {}

    it 'generates url with empty fields' do
      expect(subject).to eq(expected_url)
    end
  end

  context 'when received custom error message' do
    let(:params) do
      {
        status: status,
        request_id: entry_request.id,
        custom_message: message
      }
    end
    let(:status) { ::Payments::Webhooks::Statuses::CANCELLED }
    let(:state) { :error }
    let(:message) { 'message' }

    it 'generates correct url' do
      expect(subject).to eq(expected_url)
    end
  end
end
