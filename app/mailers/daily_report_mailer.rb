class DailyReportMailer < ApplicationMailer
  TEMPLATES = {
    daily_report_mail: ''
  }.freeze

  def daily_report_mail
    data = params[:data]
    receivers = ENV['DAILY_REPORT_EMAILS'] || ['obahriy@leobit.com']

    receivers.each do |receiver|
      smtpapi_mail(
        TEMPLATES[__method__],
        receiver,
        data
      )
    end
  end

  private

  def smtpapi_headers(template_id, substitutions = nil)
    headers(
      'X-SMTPAPI' => template_headers(template_id)
                       .merge(substitutions_headers(substitutions))
                       .to_json
    )
  end

  def smtpapi_mail(template_id, email, substitutions = nil)
    smtpapi_headers(template_id, substitutions)
    mail(to: email, content_type: 'text/html', body: '')
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

    hdrs = {}
    substitutions.each_pair do |key, value|
      hdrs["%#{key}%"] = [value]
    end

    { sub: hdrs }
  end
end
