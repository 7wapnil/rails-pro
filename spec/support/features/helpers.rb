module FeatureHelpers
  def click_submit(name: 'commit')
    find("input[name=\"#{name}\"]").click
  end

  def expect_to_have_section(section_class)
    within '.container' do
      expect(page).to have_selector ".card.#{section_class}"
    end
  end

  def expect_to_have_notification(expected_text)
    expect(page).to have_css(".flash-message[data-text=\"#{expected_text}\"]")
  end

  def resource_row_selector(resource)
    "tr##{resource.class.to_s.downcase}-#{resource.id}"
  end
end
