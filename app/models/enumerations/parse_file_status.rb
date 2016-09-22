class ParseFileStatus < EnumerateIt::Base

  associate_values(
          :to_parse => [0, 'File being parsed'],
          :finished => [1, 'Parsing successfully finished'],
          :error_finish => [2, 'Parsing finished with errors']
  )
end
