module SourceFilesHelper
  def print_status(source_file)
    case source_file.parse_status
      when 0
        "File parsing underway"
      when 1
        "File successfully parsed"
      when 2
        "There were some errors when parsing this file. #{link_to "Details", edit_source_file_path(source_file.id)}".html_safe
    end
  end
end
