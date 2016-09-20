module ActiveRecord
  class Base

    def clone_object attrs=[]
      new_obj = self.class.new
      #copy attributes
      attrs.each do |attr|
        new_obj.send(attr.to_s + "=", self.send(attr.to_s))
      end
      new_obj
    end

  end
end
