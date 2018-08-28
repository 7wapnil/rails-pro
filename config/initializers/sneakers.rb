Sneakers.configure workers: 1,
                   daemonize: false,
                   connection: Bunny.new(host: ENV['RADAR_MQ_HOST'],
                                         user: ENV['RADAR_MQ_USER'],
                                         vhost: ENV['RADAR_MQ_VHOST'],
                                         tls: ENV['RADAR_MQ_TLS'] == 'true')
