class SubmissionStatus < EnumerateIt::Base

  associate_values(
          :not_started => [0, 'Answering process is not started'],
          :underway => [1, 'Answering process is underway'],
          :submitted => [2, 'Questionnaire submitted'],
          :halted => [3, 'Answering process is halted']
  )

  DEFAULT = 4 # note: not sure why 4 does not appear in SubmissionStatus

end
