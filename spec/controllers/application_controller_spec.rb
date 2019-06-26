describe ApplicationController, type: :controller do
  controller do
    def action
      render json: {
        time: Time.zone.now,
        user_created_at: User.first.created_at
      }
    end
  end

  before do
    routes.draw do
      get 'action' => 'anonymous#action'
    end
  end

  let(:created_at_sql) { 'SELECT users.created_at FROM users LIMIT 1' }

  context 'default time zone' do
    let!(:user) { create(:user) }
    let(:created_at) do
      ActiveRecord::Base
        .connection
        .execute(created_at_sql)
        .to_a
        .first['created_at']
    end

    it 'is Tallinn' do
      expect(Time.zone.name).to eq('Tallinn')
    end

    it 'store records without timezone marks' do
      expect(created_at.length)
        .to be < 27
    end
  end

  context 'when an action requires a around filter' do
    subject do
      get :action
      JSON.parse(response.body).symbolize_keys
    end

    before { sign_in current_user }

    let(:tallinn_offset) { Time.now.in_time_zone('Tallinn').utc_offset / 3600 }
    let(:offset_str) { tallinn_offset.abs.to_s.rjust(2, '0') + ':00' }

    context 'when user time zone is not specified' do
      let(:current_user) { create(:admin_user) }

      it 'shows plain time in the default time zone' do
        expect(subject[:time].last(5)).to eq(offset_str)
      end

      it 'converts time to the default time zone' do
        expect(subject[:user_created_at].last(5)).to eq(offset_str)
      end
    end

    context 'when user has different time zone' do
      let(:current_user) { create(:admin_user, time_zone: 'UTC') }

      it 'shows plain time in the user time zone' do
        expect(subject[:time].length).to be < 27
      end

      it 'converts time to the user time zone' do
        expect(subject[:user_created_at].length).to be < 27
      end
    end
  end
end
