# frozen_string_literal: true

ActionMailer::Base.smtp_settings = { address: 'smtp.sendgrid.net',
                                     port: '587',
                                     domain: 'arcanedemo.com',
                                     authentication: :plain,
                                     user_name: 'apikey',
                                     password: ENV['SEND_GRID_API_KEY'],
                                     enable_starttls_auto: true }
