module ResourceTableHelpers
  def resource_row_selector(resource)
    "tr##{resource.class.to_s.downcase}-#{resource.id}"
  end
end
