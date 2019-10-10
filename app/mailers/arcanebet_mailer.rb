# rubocop:disable Metrics/ClassLength
# TODO split this into several mailers
class ArcanebetMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: 'ArcaneBet'

  TEMPLATES = {
    suspicious_login:               '13ea825c-23dd-4d82-bc55-fc037d2e1a49',
    account_verification_mail:      '2f09ad2c-5db2-40ee-8c62-d2781fa7bea8',
    email_verification_mail:        '0114629f-0d3d-4bcb-8f45-8377e4659be4',
    reset_password_mail:            '6ce802da-57e3-4ef0-9a0a-141f840864ac',
    negative_balance_bet_placement: 'fe39d899-cf6c-48c5-9f15-dc722d7cb6f1'
  }.freeze

  def suspicious_login(login)
    customer = find_person(login)
    domain = ENV['FRONTEND_URL']
    change_password_url = "#{domain}?changePassword=1"

    warn_suspicious_login(login) unless customer

    smtpapi_mail(
      TEMPLATES[__method__],
      customer.email,
      'changePasswordUrl': change_password_url
    )
  end

  def negative_balance_bet_placement
    customer = params[:customer]
    domain = ENV['APP_HOST']
    customer_url = "#{domain}/customers/#{customer.id}"
    receiver = ENV['ADMIN_NOTIFY_MAIL'] || 'contact@arcanebet.com'

    smtpapi_mail(
      TEMPLATES[__method__],
      receiver,
      'customerName': customer.full_name,
      'customerUrl': customer_url
    )
  end

  def account_verification_mail
    customer = params[:customer]
    domain = ENV['FRONTEND_URL']
    deposit_url = "#{domain}?depositState=1"

    smtpapi_mail(
      TEMPLATES[__method__],
      customer.email,
      'fullName':   customer.full_name,
      'depositUrl': deposit_url
    )
  end

  def email_verification_mail
    customer = params[:customer]
    domain = ENV['FRONTEND_URL']
    verification_url =
      "#{domain}/email_verification/#{customer.email_verification_token}"
    bonus_rules_url = "#{domain}/promotions/bonus-rules"

    smtpapi_mail(
      TEMPLATES[__method__],
      customer.email,
      'fullName':        customer.full_name,
      'verificationUrl': verification_url,
      'bonusRulesUrl':   bonus_rules_url
    )
  end

  def reset_password_mail(raw_token)
    domain = ENV['FRONTEND_URL']
    customer = params[:customer]
    reset_password_url = "#{domain}/reset_password/#{raw_token}"

    smtpapi_mail(
      TEMPLATES[__method__],
      customer.email,
      'fullName':         customer.full_name,
      'resetPasswordUrl': reset_password_url
    )
  end

  private

  def find_person(login)
    @person = Customer.find_for_authentication(login: login) ||
              User.find_for_authentication(email: login)
  end

  def warn_suspicious_login(login)
    Rails.logger.warn(
      "Try to send suspicious login email to unpersisted person: `#{login}`."
    )
  end

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
# rubocop:enable Metrics/ClassLength
