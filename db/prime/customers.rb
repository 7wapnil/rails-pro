customers_count = Customer.count

customers_to_create_count = 250 - customers_count

puts 'Creating Customers ...'

return unless customers_to_create_count.positive?

customers = []

customers_to_create_count.times do
  customer = Customer.new(
    username: Faker::Internet.user_name,
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    date_of_birth: Faker::Date.birthday,
    gender: Customer.genders.keys.sample,
    email: Faker::Internet.email,
    phone: Faker::PhoneNumber.phone_number,
    sign_in_count: [*1..200].sample,
    current_sign_in_at: Faker::Time.between(1.week.ago, Date.today).in_time_zone, # rubocop:disable Metrics/LineLength
    last_sign_in_at: Faker::Time.between(Date.yesterday, Date.today).in_time_zone, # rubocop:disable Metrics/LineLength
    current_sign_in_ip: Faker::Internet.ip_v4_address,
    last_sign_in_ip: Faker::Internet.ip_v4_address,
    password: 'iamverysecure'
  )

  customers << customer
end

Customer.import customers, on_duplicate_key_ignore: true

puts 'Creating Addresses ...'

addresses = []

Customer
  .where
  .not(id: Address.select(:customer_id))
  .select(:id)
  .find_each(batch_size: 50) do |customer|

  address = Address.new(
    customer_id: customer.id,
    country: Faker::Address.country,
    state: Faker::Address.state,
    city: Faker::Address.city,
    street_address: Faker::Address.street_address,
    zip_code: Faker::Address.zip_code
  )

  addresses << address
end

Address.import addresses
