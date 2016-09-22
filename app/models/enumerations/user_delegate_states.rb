class UserDelegateStates < EnumerateIt::Base
  associate_values(
          :pending => 0,
          :approved => 1,
          :rejected => 2
  )
end
