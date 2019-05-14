# frozen_string_literal: true

module Reports
  class RegistrationReports < BaseReport
    REPORT_TYPE = 'reg'
    HEADERS = %w[BTAG	BRAND	ACCOUNT_OPENING_DATE
                 PLAYER_ID USERNAME COUNTRY].freeze

    protected

    def subject_fields(subject)
      [subject.b_tag,
       ENV['BRAND'],
       subject.created_at.strftime('%d.%m.%Y'),
       subject.id,
       subject.username,
       subject.address_country]
    end

    def subjects
      Customer.where('DATE(created_at) = ?', Date.current.yesterday)
    end
  end
end
