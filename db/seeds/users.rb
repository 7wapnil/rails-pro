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
  },
  {
    first_name: 'Oleksii',
    last_name: 'Ostashchenko',
    email: 'oostashchenko@leobit.com'
  }
]

users_payload.each do |payload|
  User.find_or_create_by!(email: payload[:email]) do |user|
    user.first_name = payload[:first_name]
    user.last_name = payload[:last_name]
    user.password = ENV['SEED_USER_DEFAULT_PASSWORD']
    user.time_zone = 'Tallinn'
  end
end
