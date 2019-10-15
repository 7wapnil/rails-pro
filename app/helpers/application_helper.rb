# frozen_string_literal: true

module ApplicationHelper
  def link_back(link = nil)
    link_to t(:back), link || 'javascript:history.back()',
            class: 'btn btn-outline-dark'
  end

  def visibility_toggle(visible_resource, toggle_endpoint)
    tag.span(class: 'toggle_container') do
      toggle_id = "toggle_#{visible_resource.class.name}_#{visible_resource.id}"
      concat check_box_tag('visible', visible_resource.visible,
                           visible_resource.visible,
                           id: toggle_id,
                           class: 'toggle_button visibility_toggle',
                           data: { model: visible_resource.class.name.downcase,
                                   endpoint: toggle_endpoint })
      concat label_tag('Visible', nil, for: toggle_id)
    end
  end

  def locked_toggle(locked_resource)
    tag.span(class: 'toggle_container') do
      class_name_downcase = locked_resource.class.name.to_s.downcase
      toggle_id = "#{class_name_downcase}_locked"
      concat hidden_field_tag "#{class_name_downcase}[locked]",
                              false,
                              id: nil
      concat check_box_tag("#{class_name_downcase}[locked]",
                           true,
                           locked_resource.locked,
                           id: toggle_id,
                           class: 'toggle_button locked_toggle')
      concat label_tag('Locked', nil, for: toggle_id)
    end
  end
end
