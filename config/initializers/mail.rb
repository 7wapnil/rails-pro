ActionMailer::Base.register_interceptor(SendGrid::MailInterceptor)

ActionMailer::Base.smtp_settings = { address: 'smtp.sendgrid.net',
                                     port: '25',
                                     domain: 'arcanedemo.com',
                                     authentication: :plain,
                                     user_name: '',
                                     password: '' }
