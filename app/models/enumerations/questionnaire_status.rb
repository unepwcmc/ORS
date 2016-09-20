class QuestionnaireStatus < EnumerateIt::Base

  associate_values(
          :inactive => [0, 'Inactive'],
          :active => [1, 'Active'],
          :closed => [2, 'Closed']
  )
end
