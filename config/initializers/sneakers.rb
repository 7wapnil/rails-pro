return unless ENV['WORKERS']

sneakers_logger = ::MaskedLogStashLoggerFactory.build(type: :stdout)

sneakers_logger.level = ENV['RAILS_LOG_LEVEL'] || :debug

Sneakers.configure workers: 1,
                   log: sneakers_logger,
                   daemonize: false,
                   connection: Bunny.new(host: ENV['RADAR_MQ_HOST'],
                                         user: ENV['RADAR_MQ_USER'],
                                         vhost: ENV['RADAR_MQ_VHOST'],
                                         tls: ENV['RADAR_MQ_TLS'] == 'true')

Sneakers.logger = sneakers_logger
