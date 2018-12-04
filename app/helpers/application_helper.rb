module ApplicationHelper
  def card(opts = {})
    header = opts[:header]
    css_class = ['card', opts[:class]].join(' ')

    content_tag(:div, class: css_class) do
      concat content_tag(:h5, class: 'card-header') { header } if header
      concat content_tag(:div, class: 'card-body') { yield }
    end
  end

  def card_form_for(opts = {})
    header = opts[:header]
    css_class = ['card', opts[:class]].join(' ')
    html, resource, url = opts.extract!(:html, :resource, :url).values
    return card(opts) if html.nil? || resource.nil? || url.nil?

    content_tag(:div, class: css_class) do
      concat content_tag(:h5, class: 'card-header') { header } if header
      concat content_tag(:div, class: 'card-body') {
        simple_form_for resource, url: url, html: html do
          yield
          concat submit_button(html, resource, url)
        end
      }
    end
  end

  def options_for_verification(verified)
    options_for_select({ t('statuses.verified') => true,
                         t('statuses.not_verified') => false },
                       verified)
  end

  def link_back
    link_to t(:back), '#',
            class: 'btn btn-outline-dark', data: { button_back: true }
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

  def labels_selector(labelable, labels, element_id = nil)
    element_id ||= "#{labelable.class.to_s.downcase}_#{labelable.id}"
    update_url = polymorphic_url([:update_labels, labelable])
    placeholder = "Add #{labelable.class.to_s.downcase} label"

    collection_select(:labels, :ids, labels, :id, :name,
                      { selected: labelable.labels.ids },
                      class: 'form-control labels_selector',
                      id: element_id,
                      multiple: true,
                      data: { placeholder: placeholder,
                              update_url: update_url })
  end

  def simple_labels_selector(labelable, labels, element_id = nil)
    element_id ||= "#{labelable.class.to_s.downcase}_#{labelable.id}"
    placeholder = "Add #{labelable.class.to_s.downcase} label"
    collection_select(:labels, :ids, labels, :id, :name,
                      { selected: labelable.labels.ids },
                      class: 'form-control simple_labels_selector',
                      id: element_id,
                      multiple: true,
                      data: { placeholder: placeholder })
  end

  def content_for_days_range(resource)
    named_ranges = resource.class::NAMED_RANGES
    return named_ranges if !resource.range || named_ranges.key?(resource.range)

    { resource.range => I18n.t('days', days: resource.range) }
      .merge(named_ranges)
      .sort
      .to_h
  end

  private

  def submit_button(html, resource, url)
    render partial: 'shared/submit_card', locals: { html: html,
                                                    resource: resource,
                                                    url: url }
  end
end
