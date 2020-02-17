# frozen_string_literal: true

describe WalletEntry::PostAuthorizationService do
  include_context 'frozen_time'

  let(:entry) { create(:entry, kind.to_sym) }
  let(:kind) { EntryKinds::DEPOSIT }

  before do
    allow(::Customers::Summaries::UpdateBalance).to receive(:call)
    allow(::Wallets::BalanceVerification).to receive(:call)

    described_class.call(entry)
  end

  it 'calls summaries re-calculation' do
    expect(::Customers::Summaries::UpdateBalance)
      .to have_received(:call)
      .with(day: Date.current, entry: entry)
  end

  it 'calls balance verification' do
    expect(::Wallets::BalanceVerification)
      .to have_received(:call)
      .with(entry.customer)
  end

  context 'for bet entry' do
    let(:kind) { EntryKinds::BET }

    it 'does not call summaries re-calculation' do
      expect(::Customers::Summaries::UpdateBalance)
        .not_to have_received(:call)
    end

    it 'calls balance verification' do
      expect(::Wallets::BalanceVerification)
        .to have_received(:call)
        .with(entry.customer)
    end
  end
end
