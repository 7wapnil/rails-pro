class ApplicationMailer < ActionMailer::Base
  include Concerns::Templatable

  default from: 'noreply@arcanebet.com', subject: 'ArcaneBet'

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

    sub_headers = substitutions.each_with_object({}) do |(key, value), memo|
      variable_name = "%#{key.to_s.camelize(:lower)}%"

      memo[variable_name] = value ? [value] : ['-']
    end

    { sub: sub_headers }
  end
end
