# frozen_string_literal: true

module Bets
  class StatusEnum < Base::Enum
    graphql_name 'BetsStatusEnum'

    description 'Bet status'

    value StateMachines::BetStateMachine::INITIAL, 'Initial'
    value StateMachines::BetStateMachine::ACCEPTED, 'Accepted'
    value StateMachines::BetStateMachine::CANCELLED, 'Cancelled'
    value StateMachines::BetStateMachine::SETTLED, 'Settled'
    value StateMachines::BetStateMachine::REJECTED, 'Rejected'
    value StateMachines::BetStateMachine::FAILED, 'Failed'
  end
end
