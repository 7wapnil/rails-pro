# frozen_string_literal: true

describe Mts::ValidationMessagePublisherWorker do
  let(:bet) { create(:bet) }

  before do
    allow(Mts::Publishers::BetValidation)
      .to receive('publish!')
      .and_return(true)
  end

  it { is_expected.to be_processed_in :mts }

  it 'publishes with correct publisher' do
    expect(Mts::Publishers::BetValidation).to receive('publish!')
    subject.perform(bet.id)
  end

  it 'notifies betslip' do
    expect_any_instance_of(WebSocket::Client)
      .to receive(:trigger_bet_update)
      .with(bet)

    subject.perform(bet.id)
  end

  context 'with unexpected response from server' do
    before { allow(Mts::Publishers::BetValidation).to receive('publish!') }

    it 'raises an error' do
      expect { subject.perform(bet.id) }.to raise_error StandardError
    end
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
