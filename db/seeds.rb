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
  { name: 'Normal' },
  { name: 'VIP' },
  { name: 'Arber' },
  { name: 'Bonus Hunter' },
  { name: 'Sharp' },
  { name: 'Gambler' },
  { name: 'Staff' },
  { name: 'Watchlist' },
  { name: 'Sharp_CS' },
  { name: 'Shap_LoL' },
  { name: 'Sharp_Dota' },
  { name: 'Sharp_Tennis' },
  { name: 'Sharp_Soccer' },
  { name: 'Sharp_Basketball' },
  { name: 'Limited' },
  { name: 'Monitored' },
  { name: 'POTVIP' },
  { name: 'Industry' },
  { name: 'Test_User' },
  { name: 'Test_Customer' },
  { name: 'Live Abuser' },
  { name: 'Female' },
  { name: 'Affiliate' },
  { name: 'Youtuber' }
]

customer_labels.each do |payload|
  Label.find_or_create_by!(name: payload[:name]) do |label|
    label.name = payload[:name]
  end
end

puts 'Done!'
