class DatePickerInput < SimpleForm::Inputs::Base
  def input(_wrapper_options = nil)
    @builder.text_field(
      attribute_name,
      input_html_options.merge(class: 'form-control form_date')
    )
  end
end
