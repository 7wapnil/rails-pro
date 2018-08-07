describe Customer do
  it { should have_one(:address) }
  it { should have_many(:wallets) }
  it { should have_many(:entry_requests) }
  it { should have_and_belong_to_many(:labels) }

  it { should validate_presence_of(:username) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:date_of_birth) }

  it { should validate_uniqueness_of(:username).case_insensitive }
  it { should validate_uniqueness_of(:email).case_insensitive }

  it { should act_as_paranoid }

  it 'updates tracked fields' do
    customer = create(:customer)
    sign_in_count = customer.sign_in_count
    previous_ip = customer.current_sign_in_ip
    new_ip = Faker::Internet.ip_v4_address
    customer.update_tracked_fields!(OpenStruct.new(remote_ip: new_ip))

    expect(customer.current_sign_in_ip).to eq(new_ip)
    expect(customer.last_sign_in_ip).to eq(previous_ip)
    expect(customer.sign_in_count).to eq(sign_in_count + 1)
    expect(customer.current_sign_in_at).not_to be_nil
    expect(customer.last_sign_in_at).not_to be_nil
  end
end
