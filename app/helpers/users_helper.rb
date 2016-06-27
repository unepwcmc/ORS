module UsersHelper
  def selected_loop_item(filtering_field_id, user_id)
    obj = UserFilteringField.find_by_filtering_field_id_and_user_id(filtering_field_id, user_id)
    obj.present? ? obj.field_value : nil
  end
end
