describe Event, '#index' do
  context 'signed in' do
    include_context 'frozen_time'

    before do
      login_as create(:admin_user), scope: :user

      Timecop.travel(Time.zone.now.middle_of_day)
    end

    context 'events table' do
      let(:event) { create(:event) }
      let(:scope_kinds) { EventScope.kinds.keys }

      it 'displays event scopes' do
        scope_kinds.each do |kind|
          event.event_scopes << create(:event_scope, kind: kind)
        end

        selectors = scope_kinds.map do |kind|
          "#event-#{event.id} .#{kind} .event_scope"
        end

        visit events_path

        selectors.each do |expected_selector|
          expect(page).to have_selector(expected_selector)
        end
      end
    end
  end
end
