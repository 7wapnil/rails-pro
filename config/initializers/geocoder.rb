# frozen_string_literal: true

if Rails.env.production?
  require 'aws-sdk-s3'

  request_params = {
    bucket: ENV['IP_LOOKUP_DATABASE_BUCKET'],
    key: ENV['IP_LOOKUP_DATABASE_FILE_NAME']
  }

  File.open("tmp/#{ENV['IP_LOOKUP_DATABASE_FILE_NAME']}", 'w') do |file|
    file.puts(
      Aws::S3::Client.new.get_object(request_params).body.read
    )
  end

  Geocoder.configure(
    ip_lookup: :geoip2,
    geoip2: {
      file: File.join('tmp', ENV['IP_LOOKUP_DATABASE_FILE_NAME'])
    }
  )
else
  Geocoder.configure(
    ip_lookup: :ipinfo_io,
    cache: Redis.new
  )
end
