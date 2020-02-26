# frozen_string_literal: true

module Concerns
  module Templatable
    include ActiveSupport::Concern

    TEMPLATES = {
      suspicious_login: {
        en: '13ea825c-23dd-4d82-bc55-fc037d2e1a49'
        # pt: 'd16e14b1-548e-4c3b-93df-127d4f290213',
        # es: 'd9ae81a2-5273-44b0-a65a-55273c8626a3',
        # de: '5b5c11e4-be59-4b68-9e55-816da17a27dc'
      },
      account_verification_mail: {
        en: '2f09ad2c-5db2-40ee-8c62-d2781fa7bea8'
        # pt: 'ad6c43b6-e7bc-4c60-a0ef-0c4b6c272fd5',
        # es: '0fbf3d24-cd56-4353-8b9e-37e3f98b8ae6',
        # de: '6615db13-160b-48c0-b431-630c89545f1c'
      },
      email_verification_mail: {
        en: '0114629f-0d3d-4bcb-8f45-8377e4659be4'
        # pt: 'ae059a19-8e4e-495d-ba00-60d0a14afe5c',
        # es: 'bf3ead08-09dd-4bef-b9be-fea4293927ad',
        # de: '6b7141ab-357e-43c1-854d-8c13151d5234'
      },
      reset_password_mail: {
        en: '6ce802da-57e3-4ef0-9a0a-141f840864ac'
        # pt: 'd9bc2efd-ec0f-426f-974b-abfcf51ce0b9',
        # es: '3a793443-1e31-42ae-974e-11aa1d9f1187',
        # de: '38835817-9751-42a4-a039-c4c2ff9b8383'
      },
      negative_balance_bet_placement: {
        en: 'fe39d899-cf6c-48c5-9f15-dc722d7cb6f1'
      },
      daily_report_mail: {
        en: ENV.fetch('DAILY_REPORT_MAIL_TEMPLATE', '')
      }
    }.freeze

    def template(method, locale)
      TEMPLATES.dig(method, locale.to_sym).presence ||
        TEMPLATES.dig(method, I18n.default_locale)
    end
  end
end
