# frozen_string_literal: true

module Mts
  class Codes
    SUCCESSFUL_CODE = 1024
    DEFAULT_EXCEPTION_KEY = Bets::Notification::EXTERNAL_VALIDATION_ERROR

    MODEL_ERROR_CODES = {
      -100 => DEFAULT_EXCEPTION_KEY,
      -101 => DEFAULT_EXCEPTION_KEY,
      -102 => DEFAULT_EXCEPTION_KEY,
      -103 => DEFAULT_EXCEPTION_KEY,
      -104 => DEFAULT_EXCEPTION_KEY,
      -106 => DEFAULT_EXCEPTION_KEY,
      -107 => DEFAULT_EXCEPTION_KEY,
      -108 => DEFAULT_EXCEPTION_KEY,
      -109 => DEFAULT_EXCEPTION_KEY,
      -210 => DEFAULT_EXCEPTION_KEY,
      -211 => DEFAULT_EXCEPTION_KEY,
      -212 => DEFAULT_EXCEPTION_KEY,
      -335 => DEFAULT_EXCEPTION_KEY,
      -336 => DEFAULT_EXCEPTION_KEY
    }.freeze

    TICKET_ERROR_CODES = {
      -201 => DEFAULT_EXCEPTION_KEY,
      -202 => DEFAULT_EXCEPTION_KEY,
      -204 => DEFAULT_EXCEPTION_KEY,
      -205 => DEFAULT_EXCEPTION_KEY,
      -207 => DEFAULT_EXCEPTION_KEY,
      -209 => DEFAULT_EXCEPTION_KEY
    }.freeze

    DATA_FORMAT_ERROR_CODES = {
      -301 => DEFAULT_EXCEPTION_KEY,
      -305 => DEFAULT_EXCEPTION_KEY,
      -306 => DEFAULT_EXCEPTION_KEY,
      -307 => DEFAULT_EXCEPTION_KEY,
      -309 => DEFAULT_EXCEPTION_KEY,
      -310 => DEFAULT_EXCEPTION_KEY,
      -312 => DEFAULT_EXCEPTION_KEY,
      -313 => DEFAULT_EXCEPTION_KEY,
      -315 => DEFAULT_EXCEPTION_KEY,
      -316 => DEFAULT_EXCEPTION_KEY,
      -317 => DEFAULT_EXCEPTION_KEY,
      -319 => DEFAULT_EXCEPTION_KEY,
      -320 => DEFAULT_EXCEPTION_KEY,
      -321 => DEFAULT_EXCEPTION_KEY,
      -322 => DEFAULT_EXCEPTION_KEY
    }.freeze

    LIVE_ODDS_ERROR_CODES = {
      -401 => DEFAULT_EXCEPTION_KEY,
      -402 => DEFAULT_EXCEPTION_KEY,
      -403 => DEFAULT_EXCEPTION_KEY,
      -404 => DEFAULT_EXCEPTION_KEY,
      -405 => DEFAULT_EXCEPTION_KEY,
      -406 => DEFAULT_EXCEPTION_KEY,
      -407 => DEFAULT_EXCEPTION_KEY,
      -409 => DEFAULT_EXCEPTION_KEY,
      -410 => DEFAULT_EXCEPTION_KEY,
      -421 => DEFAULT_EXCEPTION_KEY,
      -422 => DEFAULT_EXCEPTION_KEY,
      -423 => DEFAULT_EXCEPTION_KEY
    }.freeze

    BACKOFFICE_ERROR_CODES = {
      -501 => DEFAULT_EXCEPTION_KEY,
      -502 => DEFAULT_EXCEPTION_KEY,
      -504 => DEFAULT_EXCEPTION_KEY,
      -506 => DEFAULT_EXCEPTION_KEY,
      -507 => DEFAULT_EXCEPTION_KEY,
      -508 => DEFAULT_EXCEPTION_KEY,
      -509 => DEFAULT_EXCEPTION_KEY,
      -511 => DEFAULT_EXCEPTION_KEY
    }.freeze

    RISK_MANAGEMENT_ERROR_CODES = {
      -701 => Bets::Notification::LIABILITY_LIMIT_REACHED_ERROR,
      -702 => Bets::Notification::LIABILITY_LIMIT_REACHED_ERROR,
      -703 => Bets::Notification::LIABILITY_LIMIT_REACHED_ERROR,
      -900 => DEFAULT_EXCEPTION_KEY,
      -993 => DEFAULT_EXCEPTION_KEY,
      -994 => DEFAULT_EXCEPTION_KEY,
      -999 => DEFAULT_EXCEPTION_KEY
    }.freeze

    SUBMISSION_ERROR_CODES = MODEL_ERROR_CODES
                             .merge(TICKET_ERROR_CODES)
                             .merge(DATA_FORMAT_ERROR_CODES)
                             .merge(LIVE_ODDS_ERROR_CODES)
                             .merge(BACKOFFICE_ERROR_CODES)
                             .merge(RISK_MANAGEMENT_ERROR_CODES)
                             .freeze

    CANCELLATION_ERROR_CODES = {
      -2010 => 'ticket_not_found',
      -2011 => 'inconsistent_bookmaker_code',
      -2012 => 'live_selections',
      -2013 => 'cancellation_time_expired',
      -2015 => 'pre_match_section',
      -2016 => 'cancellation_option_not_active',
      -2017 => 'ticket_already_settled',
      -999 => 'generic_exception'
    }.freeze
  end
end
