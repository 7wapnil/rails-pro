puts 'Checking customer labels list ...'

customer_labels = [
  { name: 'normal' },
  { name: 'vip' },
  { name: 'arber' },
  { name: 'bonus-hunter' },
  { name: 'sharp' },
  { name: 'gambler' },
  { name: 'staff' },
  { name: 'watchlist' },
  { name: 'sharp-cs' },
  { name: 'sharp-lol' },
  { name: 'sharp-dota' },
  { name: 'sharp-tennis' },
  { name: 'sharp-soccer' },
  { name: 'sharp-basketball' },
  { name: 'limited' },
  { name: 'monitored' },
  { name: 'pot-vip' },
  { name: 'industry' },
  { name: 'test-user' },
  { name: 'test-customer' },
  { name: 'live-abuser' },
  { name: 'female' },
  { name: 'affiliate' },
  { name: 'youtuber' }
]

customer_labels.each do |payload|
  Label.find_or_create_by!(name: payload[:name]) do |label|
    label.name = payload[:name]
  end
end
