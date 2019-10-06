# frozen_string_literal: true

module Database
  class Depersonalize < ApplicationService
    UPDATE_QUERIES =
      [
        "UPDATE customers SET
              email = 'user' || id || '@email.com',
              first_name = 'first name',
              last_name = 'last name',
              username = 'user' || id,
              current_sign_in_ip = null,
              last_sign_in_ip = null,
              sign_up_ip = null,
              phone = null",
        "UPDATE addresses SET
              country = 'country ' || id,
              state = 'state ' || id,
              city = 'city ' || id,
              street_address = 'street address ' || id,
              zip_code = 'zip code' || id",
        'UPDATE customer_data SET ip_last = null',
        'UPDATE customer_transactions SET details = null'
      ].freeze

    DELETE_QUERIES =
      [
        'DELETE from active_storage_blobs',
        'DELETE from login_activities'
      ].freeze

    def call
      puts 'Starting depersonalization'

      start_time = Time.now

      UPDATE_QUERIES.each { |query| execute_query(query) }
      DELETE_QUERIES.each { |query| execute_query(query) }

      puts "Executed in #{Time.now - start_time}s"
      puts 'Finished depersonalization'
    end

    private

    def execute_query(query)
      ActiveRecord::Base.connection.execute(query)
    end
  end
end
