# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::PaymentDetails::RequestHandler do
  include_context 'safecharge_env'

  subject { described_class.call(params) }

  let(:deposit) { create(:deposit) }
  let(:mode) { EntryRequest::SKRILL }
  let(:entry_request) { create(:entry_request, mode: mode, origin: deposit) }
  let(:customer) { entry_request.customer }
  let(:payment_option_id) { '1' }
  let(:params) do
    { entry_request: entry_request, payment_option_id: payment_option_id }
  end

  let(:payment_options_payload) do
    JSON.parse(
      file_fixture('payments/fiat/safe_charge/get_user_UPOs.json').read
    )
  end

  before do
    allow_any_instance_of(::Payments::Fiat::SafeCharge::Client)
      .to receive(:receive_user_payment_options)
      .and_return(payment_options_payload)
  end

  it 'stores fetched payment option details' do
    subject
    expect(deposit.reload.details).to include(
      'user_payment_option_id' => '1',
      'name' => '322322322'
    )
  end

  context 'with found identical payment option' do
    let(:name) { Faker::WorldOfWarcraft.hero }

    let!(:successful_deposit) do
      create(:deposit, details: { user_payment_option_id: '1', name: name })
    end

    let!(:successful_deposit_entry_request) do
      create(:entry_request, :deposit, :succeeded,
             customer: customer,
             origin: successful_deposit)
    end

    let!(:successful_entry) do
      create(:entry, entry_request: successful_deposit_entry_request)
    end

    it 'stores found payment option details' do
      subject
      expect(deposit.reload.details).to include(
        'user_payment_option_id' => '1',
        'name' => name
      )
    end
  end

  context 'when payment option is not found using API' do
    let(:payment_option_id) { -1 }
    let(:mode) { [EntryRequest::SKRILL, EntryRequest::NETELLER].sample }

    it 'stores found payment option details' do
      subject
      expect(deposit.reload.details).to include(
        'user_payment_option_id' => '-1',
        'name' => I18n.t("kinds.payment_methods.#{mode}")
      )
    end
  end

  context 'when payment option API call returns an error' do
    let(:payment_options_payload) { {} }
    let(:mode) { [EntryRequest::SKRILL, EntryRequest::NETELLER].sample }

    it 'stores found payment option details' do
      subject
      expect(deposit.reload.details).to include(
        'user_payment_option_id' => '1',
        'name' => I18n.t("kinds.payment_methods.#{mode}")
      )
    end
  end
end
