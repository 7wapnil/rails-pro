puts 'Checking system users ...'

users_payload = [
  {
    first_name: 'Tim',
    last_name: 'Hurks',
    email: 't.hurks@arcanebet.com'
  },
  {
    first_name: 'Claude',
    last_name: 'Du Toit',
    email: 'claude@arcanebet.com'
  },
  {
    first_name: 'Stanislav',
    last_name: 'Gorski',
    email: 'stanislav@arcanebet.com'
  },
  {
    first_name: 'Igor',
    last_name: 'Murujev',
    email: 'igor@arcanebet.com'
  },
  {
    first_name: 'Bux',
    last_name: 'Syed',
    email: 'bux@arcanebet.com'
  },
  {
    first_name: 'Tanel',
    last_name: 'Liinak',
    email: 'tanel@arcanebet.com'
  }
]

users_payload.each do |payload|
  User.find_or_create_by!(email: payload[:email]) do |user|
    user.first_name = payload[:first_name]
    user.last_name = payload[:last_name]
    user.password = ENV['SEED_USER_DEFAULT_PASSWORD']
  end
end

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

puts 'Done!'
