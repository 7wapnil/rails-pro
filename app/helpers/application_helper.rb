module ApplicationHelper
  def card(opts = {})
    header = opts[:header]
    css_class = ['card', opts[:class]].join(' ')

    content_tag(:div, class: css_class) do
      concat content_tag(:h5, class: 'card-header') { header } if header
      concat content_tag(:div, class: 'card-body') { yield }
    end
  end

  def link_back
    link_to t(:back), 'javascript:window.history.back();',
            class: 'btn btn-outline-dark'
  end

  def visibility_toggle(visible_resource, toggle_endpoint)
    tag.span(class: 'toggle_container') do
      toggle_id = "toggle_#{visible_resource.class.name}_#{visible_resource.id}"
      concat check_box_tag('visible', visible_resource.visible,
                           visible_resource.visible,
                           id: toggle_id,
                           class: 'toggle_button visibility_toggle',
                           data: { endpoint: toggle_endpoint })
      concat label_tag('Visible', nil, for: toggle_id)
    end
  end

  def labels_selector(labelable, labels)
    update_url = polymorphic_url([:update_labels, labelable])
    placeholder = "Add #{labelable.class.to_s.downcase} label"

    collection_select(:labels,
                      :ids,
                      labels,
                      :id,
                      :name,
                      { selected: labelable.labels.map(&:id) },
                      class: 'form-control',
                      id: 'select_labels',
                      multiple: true,
                      data: { placeholder: placeholder,
                              update_url: update_url })
  end
end
