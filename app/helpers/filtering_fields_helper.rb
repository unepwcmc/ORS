module FilteringFieldsHelper
  def check_loop_source_item_type(filtering_field, loop_source)
    filtering_field.loop_item_types.each do |item_type|
      if item_type.root.loop_source == loop_source
        return item_type.id
      end
    end
    nil
  end
end
