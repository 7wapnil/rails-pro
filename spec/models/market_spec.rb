# frozen_string_literal: true

describe Market do
  subject(:market) { described_class.new }

  it { is_expected.to belong_to(:event) }
  it { is_expected.to belong_to(:template) }
  it { is_expected.to have_many(:odds) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:priority) }
  it { is_expected.to validate_presence_of(:status) }

  context 'callbacks' do
    it 'calls priority definition before validation' do
      allow(subject).to receive(:define_priority)
      subject.name = 'New name'
      subject.validate
      expect(subject).to have_received(:define_priority)
    end

    it 'does not call priority definition before save if name not changed' do
      allow(subject).to receive(:define_priority)
      subject.validate
      expect(subject).not_to have_received(:define_priority)
    end

    describe '#snapshot_status!' do
      subject(:market) { create(:market) }

      before { market }

      it 'is not called' do
        expect(Markets::StatusTransition).not_to receive(:call)
        market.save
      end

      it 'is called on change status' do
        market.status = StateMachines::MarketStateMachine::SUSPENDED
        expect(Markets::StatusTransition)
          .to receive(:call)
          .with(
            market: market,
            status: StateMachines::MarketStateMachine::SUSPENDED
          )
        market.save
      end
    end
  end

  context 'priority' do
    it 'defines 1 priority by default' do
      subject.name = 'Unknown name'
      subject.validate
      expect(subject.priority).to eq(1)
    end

    %w[Winner 1x2].each do |market_name|
      it "defines 1 priority for market name '#{market_name}'" do
        subject.name = market_name
        subject.validate
        expect(subject.priority).to eq(0)
      end
    end
  end

  [
    %i[settled active],
    %i[settled inactive],
    %i[settled suspended],
    %i[cancelled active],
    %i[cancelled inactive],
    %i[cancelled suspended],
    %i[cancelled settled]
  ].each do |initial_state, new_state|
    it "raises error on switching from '#{initial_state}' to '#{new_state}'" do
      market = create(:market, status: initial_state)
      market.status = new_state
      expect(market).not_to be_valid
      error_msg = I18n.t('errors.messages.wrong_market_state',
                         initial_state: initial_state,
                         new_state: new_state)
      expect(market.errors[:status][0]).to eq(error_msg)
    end
  end

  [
    %i[active cancelled],
    %i[inactive cancelled],
    %i[suspended settled],
    %i[suspended cancelled],
    %i[active settled],
    %i[active inactive],
    %i[active suspended],
    %i[active handed_over],
    %i[inactive active],
    %i[inactive settled],
    %i[inactive handed_over],
    %i[suspended active],
    %i[suspended inactive],
    %i[suspended handed_over],
    %i[settled handed_over],
    %i[cancelled handed_over],
    %i[inactive suspended]
  ].each do |initial_state, new_state|
    it "allows switching from '#{initial_state}' to '#{new_state}'" do
      market = create(:market, status: initial_state)
      market.status = new_state
      market.valid?
      expect(market.errors[:status]).to be_blank
    end
  end

  describe '#for_displaying' do
    before do
      StateMachines::MarketStateMachine::STATUSES.values.each do |status|
        FactoryBot.create(:market, :with_odds, status: status)
      end
    end

    let(:extra_market) do
      create(:market, :with_odds,
             status: extra_market_status,
             priority: extra_market_priority)
    end

    context 'with priority 0 inactive market' do
      let(:extra_market_priority) { 0 }
      let(:extra_market_status) do
        StateMachines::MarketStateMachine::INACTIVE
      end

      it 'returns markets with visible statuses and inactive priority 0' do
        expected_to_be_displayed =
          [extra_market] +
          described_class.where(
            status: StateMachines::MarketStateMachine::DISPLAYED_STATUSES
          )

        expect(described_class.for_displaying)
          .to match_array(expected_to_be_displayed)
      end
    end

    context 'with priority 1 inactive market' do
      let(:extra_market_priority) { 1 }
      let(:extra_market_status) do
        StateMachines::MarketStateMachine::INACTIVE
      end

      it 'returns only markets with visible statuses' do
        expected_to_be_displayed =
          described_class.where(
            status: StateMachines::MarketStateMachine::DISPLAYED_STATUSES
          )

        expect(described_class.for_displaying)
          .to match_array(expected_to_be_displayed)
      end
    end

    context 'with priority 0 active market' do
      let(:extra_market_priority) { 0 }
      let(:extra_market_status) do
        StateMachines::MarketStateMachine::ACTIVE
      end

      it 'returns only markets with visible statuses' do
        expected_to_be_displayed =
          described_class.where(
            status: StateMachines::MarketStateMachine::DISPLAYED_STATUSES
          )

        expect(described_class.for_displaying)
          .to match_array(expected_to_be_displayed)
      end
    end

    context 'with priority 1 active market' do
      let(:extra_market_priority) { 1 }
      let(:extra_market_status) do
        StateMachines::MarketStateMachine::ACTIVE
      end

      it 'returns only markets with visible statuses' do
        expected_to_be_displayed =
          described_class.where(
            status: StateMachines::MarketStateMachine::DISPLAYED_STATUSES
          )

        expect(described_class.for_displaying)
          .to match_array(expected_to_be_displayed)
      end
    end
  end

  describe '#rollback_status!' do
    subject(:market) { build(:market) }

    it 'works with default args' do
      expect(Markets::StatusTransition)
        .to receive(:call)
        .with(market: market, persist: true)

      market.rollback_status!
    end

    it 'works without persisting' do
      expect(Markets::StatusTransition)
        .to receive(:call)
        .with(market: market, persist: false)

      market.rollback_status!(persist: false)
    end

    it 'works with persisting' do
      expect(Markets::StatusTransition)
        .to receive(:call)
        .with(market: market, persist: true)

      market.rollback_status!(persist: true)
    end
  end
end
