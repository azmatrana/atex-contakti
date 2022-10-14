class CustomCheckboxInput < ::SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    if nested_boolean_style?
      build_hidden_field_for_checkbox +
        template.label_tag(nil, class: SimpleForm.boolean_label_class) {
          build_check_box_without_hidden_field(merged_input_options) +
            inline_label
        }
    else
      build_check_box(unchecked_value, merged_input_options)
    end
  end

  def label_input(wrapper_options = nil)
    input(wrapper_options) + '<i class="fa fa-fw fa-square-o checked"></i>'.html_safe + label_text
  end
end