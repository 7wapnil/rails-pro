# frozen_string_literal: true

module UP
  class Import < ApplicationService # rubocop:disable Metrics/ClassLength
    CURRENCY_NAME_MAP = {
      'US Dollars'        => { code: 'USD',  factor: 1.0 },
      'Turkish Lira'      => { code: 'TRY',  factor: 1.0 },
      'Euro'              => { code: 'EUR',  factor: 1.0 },
      'Canadian Dollar'   => { code: 'CAD',  factor: 1.0 },
      'Australian Dollar' => { code: 'AUD',  factor: 1.0 },
      'Norwegian Krone'   => { code: 'NOK',  factor: 1.0 },
      'Danish Krone'      => { code: 'DKK',  factor: 1.0 },
      'Swedish Krona'     => { code: 'SEK',  factor: 1.0 },
      'Russian Rouble'    => { code: 'RUB',  factor: 1.0 },
      'Bitcoin'           => { code: 'mBTC', factor: 1000.0 },
      'British Pound'     => { code: 'GBP',  factor: 1.0 }
    }.freeze

    def initialize(import_file, error_file)
      @import_file = import_file
      @error_file = error_file
    end

    def call
      each_detail do |row|
        customer = create_customer(row)
        create_address(customer, row)
        currency, amount = currency_and_amount(row)
        wallet = create_wallet(customer, currency)
        create_balance(wallet, amount)
      end

      puts "Rows processed:  #{@row_count}"
      puts "Errors detected: #{@error_count}"
    end

    private

    attr_reader :import_file, :error_file

    def account_details
      @account_details ||= CSV.read(import_file)
    end

    def headers
      @headers ||= account_details.first
    end

    def each_detail
      create_error_workbook

      @row_count = 0
      # drop(1) to skip the headers row
      account_details.drop(1).each do |raw_row|
        row = Hash[headers.zip(raw_row)]

        begin
          @row_count += 1
          yield row
        rescue StandardError => error
          record_error_row(raw_row, error)

          next
        end
      end
    end

    def create_customer(row)
      Customer.find_or_initialize_by(external_id: row['AccountID']) do |c|
        new_customer = c.new_record?
        attributes = customer_attribures(row)
        attributes[:password] = Devise.friendly_token if new_customer
        c.update_attributes!(attributes)
        c.update_column(:encrypted_password, '') if new_customer
      end
    end

    def create_address(customer, row)
      Address.find_or_initialize_by(customer: customer) do |a|
        a.update_attributes!(address_attributes(customer, row))
      end
    end

    def create_wallet(customer, currency)
      Wallet.find_or_create_by!(
        customer: customer,
        currency: currency
      )
    end

    def create_balance(wallet, amount)
      Balance.find_or_initialize_by(wallet: wallet,
                                    kind: Balance::REAL_MONEY) do |b|
        b.update_attributes!(amount: amount)
      end

      wallet.update_attributes!(
        amount: wallet.balances.pluck(:amount).sum
      )
    end

    def create_error_workbook
      @error_spreadsheet = CSV.open(error_file, 'wb')

      @error_spreadsheet << (headers + ['Error'])

      @error_count = 0
    end

    def record_error_row(raw_row, error)
      @error_count += 1

      @error_spreadsheet << (raw_row + [error.message])
    end

    def customer_attribures(row) # rubocop:disable Metrics/MethodLength
      {
        external_id:   row['AccountID'],
        first_name:    row['FirstName'],
        last_name:     row['LastName'],
        date_of_birth: row['DateofBirth'],
        email:         row['EmailAddress'],
        username:      row['UserName'],
        created_at:    row['RegistrationDate'],
        sign_up_ip:     row['RegistrationIP'],
        b_tag:         agent(row),
        verified:      verified(row),
        locked:        locked(row),
        gender:        gender(row),
        phone:         phone(row)
      }
    end

    def address_attributes(customer, row)
      {
        customer:       customer,
        country:        row['CountryName'],
        state:          row['StateOrProvince'],
        city:           row['City'],
        street_address: row['Street'],
        zip_code:       row['Zip']
      }
    end

    def currency_and_amount(row)
      currency_name = row['CurrencyName']
      currency = currencies.dig(currency_name, :currency)
      original_amount = row['Balance'].to_f
      currency = primary_currency if original_amount.zero? && currency.nil?

      raise "No currency mapping for '#{currency_name}'" if currency.nil?

      amount = original_amount * currencies.dig(currency_name, :factor).to_f

      [currency, amount]
    end

    def currencies
      @currencies ||= CURRENCY_NAME_MAP.transform_values do |currency_hash|
        currency_hash.merge(
          currency: Currency.find_by(code: currency_hash[:code])
        )
      end
    end

    def primary_currency
      @primary_currency ||= Currency.find_by(code: ::Currency::PRIMARY_CODE)
    end

    def gender(row)
      row['Gender'].downcase
    end

    def verified(row)
      row['VerificationStatus']&.downcase == 'true'
    end

    def locked(row)
      row['AccountStatus'] == 'Lock'
    end

    def phone(row)
      country =
        ISO3166::Country
        .find_country_by_name(row['CountryName'])

      phone = Phonelib.parse(
        row['PhoneNumber'],
        country&.alpha2
      )

      phone.full_international
    end

    def agent(row)
      row['AgentName'] unless row['AgentName'] == 'NULL'
    end
  end
end
