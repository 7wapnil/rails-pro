# frozen_string_literal: true

module EveryMatrix
  module StateMachines
    module FreeSpinBonusWalletStateMachine
      extend ActiveSupport::Concern

      INITIAL = 'initial'
      SENT_TO_CREATE_USER = 'sent_to_create_user'
      USER_CREATED = 'user_created'
      USER_CREATED_WITH_ERROR = 'user_created_with_error'
      SENT_TO_AWARD = 'sent_to_award'
      AWARDED = 'awarded'
      AWARDED_WITH_ERROR = 'awarded_with_error'
      SENT_TO_FORFEIT = 'sent_to_forfeit'
      FORFEITED = 'forfeited'
      FORFEITED_WITH_ERROR = 'forfeited_with_error'

      STATUSES = {
        initial: INITIAL,
        sent_to_create_user: SENT_TO_CREATE_USER,
        user_created: USER_CREATED,
        user_created_with_error: USER_CREATED_WITH_ERROR,
        sent_to_award: SENT_TO_AWARD,
        awarded: AWARDED,
        awarded_with_error: AWARDED_WITH_ERROR,
        sent_to_forfeit: SENT_TO_FORFEIT,
        forfeited: FORFEITED,
        forfeited_with_error: FORFEITED_WITH_ERROR
      }.freeze

      ERROR_STATUSES = [
        USER_CREATED_WITH_ERROR,
        AWARDED_WITH_ERROR,
        FORFEITED_WITH_ERROR
      ].freeze

      IN_PROGRESS_STATUSES = [
        SENT_TO_CREATE_USER,
        SENT_TO_AWARD,
        SENT_TO_FORFEIT
      ].freeze

      included do
        enum status: STATUSES

        include AASM

        aasm column: :status, enum: true do
          state :initial, initial: true
          state :sent_to_create_user
          state :user_created
          state :user_created_with_error
          state :sent_to_award
          state :awarded
          state :awarded_with_error
          state :sent_to_forfeit
          state :forfeited
          state :forfeited_with_error

          event :send_to_award do
            transitions from: :initial,
                        to: :sent_to_award
          end

          event :send_to_create_user do
            transitions from: :initial,
                        to: :sent_to_create_user
          end

          event :create_user do
            transitions from: :sent_to_create_user,
                        to: :user_created
          end

          event :create_user_with_error do
            transitions from: :sent_to_create_user,
                        to: :user_created_with_error
          end

          event :send_to_award do
            transitions from: %i[initial user_created],
                        to: :sent_to_award
          end

          event :award do
            transitions from: :sent_to_award,
                        to: :awarded
          end

          event :award_with_error do
            transitions from: :sent_to_award,
                        to: :awarded_with_error
          end

          event :send_to_forfeit do
            transitions from: %i[awarded awarded_with_error],
                        to: :sent_to_forfeit
          end

          event :forfeit do
            transitions from: :sent_to_forfeit,
                        to: :forfeited
          end

          event :forfeit_with_error do
            transitions from: :sent_to_forfeit,
                        to: :forfeited_with_error
          end
        end
      end
    end
  end
end
