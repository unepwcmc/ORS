class ExtraFieldType < EnumerateIt::Base
  associate_values(
          :image => 0,
          :text => 1,
          :link => 2
  )
end
