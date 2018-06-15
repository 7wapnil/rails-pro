module FeatureHelpers
  def click_submit(name: 'commit')
    find("input[name=\"#{name}\"]").click
  end

  def expect_to_have_section(section_class)
    within '.container' do
      expect(page).to have_selector ".card.#{section_class}"
    end
  end
end
