# frozen_string_literal: true

describe Customers::CreateFakeDeposit do
  subject { described_class.call(customer: customer, params: params) }

  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let(:amount) { rand(1..100) }

  let(:mocked_entry_request) { create(:entry_request) }
  let(:credit) { {} }

  let(:params) do
    {
      amount: amount,
      currency_id: currency.id
    }
  end

  before do
    allow_any_instance_of(PaymentProvider::FakeDeposit)
      .to receive(:pay!)
      .and_return(true)

    allow(EntryRequests::Factories::Deposit)
      .to receive(:call)
      .and_return(mocked_entry_request)

    allow(EntryRequests::DepositService)
      .to receive(:call)
      .with(entry_request: mocked_entry_request)
  end

  it 'asks payment provider to perform payment' do
    expect_any_instance_of(PaymentProvider::FakeDeposit)
      .to receive(:pay!)
      .with(amount, credit)
      .once

    subject
  end

  it 'creates wallet without created wallet' do
    expect { subject }.to change(Wallet, :count).by(1)
  end

  it 'returns truthy value on success payment' do
    expect(subject).to be_truthy
  end

  context 'on invalid payment' do
    before do
      allow_any_instance_of(PaymentProvider::FakeDeposit)
        .to receive(:pay!)
        .and_return(false)

      subject
    end

    it 'returns falsey' do
      expect(subject).to be_falsey
    end

    it 'fails entry request' do
      expect(mocked_entry_request).to have_attributes(
        status: EntryRequest::FAILED,
        result: {
          'message' => I18n.t('errors.messages.deposit_payment_error')
        }
      )
    end
  end

  context 'with pre-created wallet' do
    let!(:wallet) do
      create(:wallet, customer: customer, currency: currency)
    end

    it 'creates entry request using factory' do
      expect(EntryRequests::Factories::Deposit)
        .to receive(:call)
        .with(wallet: wallet, amount: amount)

      subject
    end

    it 'calls Deposit Service to proceed entry request' do
      allow(EntryRequests::DepositService)
        .to receive(:call)
        .with(entry_request: mocked_entry_request)

      subject
    end

    it "doesn't create wallet" do
      expect { subject }.not_to change(Wallet, :count)
    end
  end

  context 'if entry request failed' do
    let(:mocked_entry_request) do
      create(:entry_request, status: EntryRequest::FAILED)
    end

    it 'does not call payment provider ' do
      expect_any_instance_of(PaymentProvider::FakeDeposit)
        .not_to receive(:pay!)

      subject
    end

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end
end