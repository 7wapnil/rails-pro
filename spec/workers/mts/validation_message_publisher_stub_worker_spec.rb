# frozen_string_literal: true

describe Mts::ValidationMessagePublisherStubWorker do
  let(:bet) { create(:bet, :sent_to_external_validation) }

  before { allow_any_instance_of(described_class).to receive(:sleep) }

  it { is_expected.to be_processed_in :default }

  it 'accepts bet' do
    subject.perform(bet.id)
    expect(bet.reload.status).to eq(StateMachines::BetStateMachine::ACCEPTED)
  end

  it 'notifies betslip' do
    expect_any_instance_of(WebSocket::Client)
      .to receive(:trigger_bet_update)
      .with(bet)

    subject.perform(bet.id)
  end

  context 'with bet not found' do
    let(:bet) {}
    let(:id) { 'wrong-id' }

    it 'raises an error' do
      expect { subject.perform(id) }.to raise_error(
        ActiveRecord::RecordNotFound,
        I18n.t('errors.messages.nonexistent_bet', id: id)
      )
    end
  end
end
