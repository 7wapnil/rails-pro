module FeatureHelpers
  def click_submit(name: 'commit')
    find("input[name=\"#{name}\"]").click
  end

  def expect_to_have_section(section_class)
    within '.container, .container-fluid' do
      expect(page).to have_selector ".card.#{section_class}"
    end
  end

  def expect_to_have_notification(expected_text)
    expect(page).to have_css(".flash-message[data-text=\"#{expected_text}\"]")
  end

  def resource_row_selector(resource)
    "tr##{resource.class.to_s.downcase}-#{resource.id}"
  end

  def sort_in_asc_direction?(link_href)
    link_href.downcase.ends_with? 'asc'
  end

  def sort_in_desc_direction?(link_href)
    link_href.downcase.ends_with? 'desc'
  end
end

module RequestSpecHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before { Warden.test_mode! }
    base.after { Warden.test_reset! }
  end

  def sign_in(resource)
    login_as(resource, scope: warden_scope(resource))
  end

  def sign_out(resource)
    logout(warden_scope(resource))
  end

  private

  def warden_scope(resource)
    resource.class.name.underscore.to_sym
  end
end
