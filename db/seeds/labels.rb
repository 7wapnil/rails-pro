puts 'Checking labels list ...'

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

system_customer_labels = Label::RESERVED_BY_SYSTEM.map do |keyword|
  {
    keyword: keyword,
    system: true
  }
end

event_labels = [
  { name: 'event_label' },
  { name: 'cool_event' },
  { name: 'new_event' },
  { name: 'hot_event' }
]

market_labels = [
  { name: 'market_label' },
  { name: 'market_top10' },
  { name: 'market_hot' },
  { name: 'market_new' }
]

customer_labels.each do |payload|
  Label.find_or_create_by!(name: payload[:name],
                           kind: Label::CUSTOMER) do |label|
    label.name = payload[:name]
  end
end

system_customer_labels.each do |payload|
  next if Label.find_by(**payload, kind: Label::CUSTOMER)

  Label.new(**payload, kind: Label::CUSTOMER).save(validate: false)
end

event_labels.each do |payload|
  Label.find_or_create_by!(name: payload[:name], kind: Label::EVENT) do |label|
    label.name = payload[:name]
  end
end

market_labels.each do |payload|
  Label.find_or_create_by!(name: payload[:name], kind: Label::MARKET) do |label|
    label.name = payload[:name]
  end
end
