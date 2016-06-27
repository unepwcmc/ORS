class SectionType < EnumerateIt::Base

  associate_values(
          :looping => [0, 'Looping section'],
          :same_answer_type => [1, 'Same answer type section'],
          :regular => [2, 'Regular section']
  )
end
