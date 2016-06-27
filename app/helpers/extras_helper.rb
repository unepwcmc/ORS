module ExtrasHelper
  def available_extras section, selected_item_type, ignore_self
    extras = []
    branch_to_check = ignore_self ? "ancestors" : "self_and_ancestors"
    section.send(branch_to_check).each do |s|
      if s.loop_item_type
        extras += s.loop_item_type.extras
      end
    end
    if selected_item_type
      extras += selected_item_type.extras
    end
    extras
  end
end
