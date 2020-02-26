# frozen_string_literal: true

class DailyReportMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: I18n.t('internal.mailers.daily_report_mailer.subject')

  def daily_report_mail
    data = params[:data]
    receivers = ENV.fetch('DAILY_REPORT_EMAILS', '').split(',')

    return if receivers.blank?

    smtpapi_mail(
      template(__method__, I18n.default_locale),
      receivers,
      data
    )
  end

  private

  def substitutions_headers(substitutions = nil)
    return {} unless substitutions

    sub_headers = substitutions.each_with_object({}) do |(key, value), memo|
      variable_name = "%#{key.camelize(:lower)}%"

      memo[variable_name] = value ? [value] : ['-']
    end

    { sub: sub_headers }
  end
end
