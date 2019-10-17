# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module ErrorCodes
        GATEWAY_FILTER_ERROR_CODE = '-1100'
        CODES_MAP = {
          '001'  => 'Invalid expiration date.',
          '1002' => 'Expiration date has already passed.',
          '1101' => 'Invalid card number (alpha numeric).',
          '1102' => 'Invalid card number (length).',
          '1103' => 'Invalid card number (MOD 10).',
          '1104' => 'Invalid CVV2.',
          '1105' => 'Auth Code/Trans ID/Credit card number mismatch.',
          '1106' => 'Credit amount exceeds total charges.',
          '1107' => 'Cannot credit this credit card company.',
          '1108' => 'Invalid interval between authorisation and settle.',
          '1109' => 'Unable to process this credit card company.',
          '1110' => 'Unrecognised credit card company.',
          '1111' => 'This transaction was charged back.',
          '1112' => 'Sale/Settle was already credited.',
          '1113' => 'Terminal is not ready for this credit card company.',
          '1114' => 'Black listed card number.',
          '1115' => 'Illegal BIN number.',
          '1116' => 'Custom Fraud Screen Filter.',
          '1118' => 'N cannot be a Positive CVV2 reply.',
          '1119' => 'B/N cannot be a Positive AVS reply.',
          '1120' => 'Invalid AVS.',
          '1121' => 'CVV2 check is not allowed in Credit/Settle/Void.',
          '1122' => 'AVS check is not allowed in Credit/Settle/Void.',
          '1124' => 'Credits total amount exceeds restriction.',
          '1125' => 'Format error.',
          '1126' => 'Credit amount exceeds limit.',
          '1127' => 'Limit exceeding amount.',
          '1128' => 'Invalid transaction type code.',
          '1129' => 'General filter error.',
          '1130' => 'The banks required fields are blank or incorrect.',
          '1131' => 'This transaction type is not allowed for this bank.',
          '1132' => 'Amount exceeds bank limit.',
          '1133' => 'Gateway required fields are missing.',
          '1134' => 'AVS processor error.',
          '1135' => 'Only one credit per sale is allowed.',
          '1136' => 'Mandatory fields are missing.',
          '1137' => 'Credit count exceeded credit card company restriction.',
          '1138' => 'Invalid credit type.',
          '1139' => 'This card is not supported in the CFT Program.'
        }.freeze

        def error_message_by_code(code)
          CODES_MAP[code.to_s]
        end
      end
    end
  end
end
