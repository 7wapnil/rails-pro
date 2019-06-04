# frozen_string_literal: true

module Reports
  class RegistrationReport < BaseReport
    REPORT_TYPE = 'reg'
    HEADERS = %w[BTAG	BRAND	ACCOUNT_OPENING_DATE
                 PLAYER_ID USERNAME COUNTRY].freeze

    protected

    def subject_fields(subject)
      [subject.b_tag,
       ENV['BRAND'],
       subject.created_at.strftime('%Y-%m-%d'),
       subject.id,
       subject.username,
       subject.address.country_code]
    end

    def subjects
      Customer.where('DATE(created_at) = ? AND b_tag != ?',
                     Date.current.yesterday, '')
    end
  end
end