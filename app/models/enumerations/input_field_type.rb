class InputFieldType < EnumerateIt::Base
  associate_values(
          :check_box => 0,
          :radio_button => 1,
          :text_field => 2,
          :drop_down_list => 3
  )
end
