module FeatureHelpers
  def click_submit(name: 'commit')
    find("input[name=\"#{name}\"]").click
  end
end
