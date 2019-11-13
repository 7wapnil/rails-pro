# frozen_string_literal: true

class DailyReportMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: I18n.t('mailers.daily_report_mailer.subject')

  TEMPLATES = {
    daily_report_mail: 'cc35259a-0e1f-47e5-94bd-ba8faa03d7fe'
  }.freeze

  def daily_report_mail
    data = params[:data]
    receivers = ENV.fetch('DAILY_REPORT_EMAILS', '').split(',')

    return if receivers.blank?

    smtpapi_mail(
      TEMPLATES[__method__],
      receivers,
      data
    )
  end

  private

  def smtpapi_mail(template_id, email, substitutions = nil)
    smtpapi_headers(template_id, substitutions)
    mail(to: email, content_type: 'text/html', body: '')
  end

  def smtpapi_headers(template_id, substitutions = nil)
    headers(
      'X-SMTPAPI' => template_headers(template_id)
                       .merge(substitutions_headers(substitutions))
                       .to_json
    )
  end

  def template_headers(template_id)
    {
      filters: {
        templates: {
          settings: {
            enable: 1,
            template_id: template_id
          }
        }
      }
    }
  end

  def substitutions_headers(substitutions = nil)
    return {} unless substitutions

    sub_headers = substitutions.each_with_object({}) do |(key, value), memo|
      variable_name = "%#{key.camelize(:lower)}%"

      memo[variable_name] = value ? [value] : ['-']
    end

    { sub: sub_headers }
  end
end
