# frozen_string_literal: true

describe Markets::StatusTransition do
  subject { described_class.call(params) }

  let(:market) { create(:market, previous_status: nil) }
  let(:status) { StateMachines::MarketStateMachine::SETTLED }
  let(:default_params) { { market: market, status: status } }
  let(:params) { default_params }

  context 'status transition' do
    before { subject }

    it 'does not save market changes to db' do
      expect(market.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::ACTIVE,
        previous_status: nil
      )
    end

    it 'changes market statuses' do
      expect(market).to have_attributes(
        status: StateMachines::MarketStateMachine::SETTLED,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end

    context 'with persist param' do
      let(:params) { default_params.merge(persist: true) }

      it 'saves market with valid attributes' do
        expect(market.reload).to have_attributes(
          status: StateMachines::MarketStateMachine::SETTLED,
          previous_status: StateMachines::MarketStateMachine::ACTIVE
        )
      end
    end
  end

  context 'status rollback' do
    let(:status) {}
    let(:market) { create(:market, :settled) }

    it 'does not save market changes to db' do
      subject
      expect(market.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::SETTLED,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end

    it 'changes market statuses' do
      subject
      expect(market).to have_attributes(
        status: StateMachines::MarketStateMachine::ACTIVE,
        previous_status: nil
      )
    end

    context 'with persist param' do
      let(:params) { default_params.merge(persist: true) }

      it 'saves market with valid attributes' do
        expect(market.reload).to have_attributes(
          status: StateMachines::MarketStateMachine::SETTLED,
          previous_status: StateMachines::MarketStateMachine::ACTIVE
        )
      end
    end

    context 'without previous status' do
      let(:market) { create(:market, :settled, previous_status: nil) }
      let(:error_message) do
        "There is no status snapshot for market #{market.external_id}!"
      end

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError, error_message)
      end
    end
  end
end
