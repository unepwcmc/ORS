class QuestionnairePdf < Prawn::Document
  require "open-uri"

  CHECK_BOX = "\xE2\x98\x90"
  FILLED_CHECK_BOX = "\xE2\x98\x91"

  attr_reader :logger

  def initialize
    super()
    @coder = HTMLEntities.new
    @logger = Logger.new("#{Rails.root}/log/sidekiq.log")
  end

  # Generates a PDF file for questionnaire with the user's answers.
  # If short_version is true it will only print the section and/or questions that have answers
  def to_pdf  requester, user, questionnaire, url_prefix, short_version=false
    font_families.update(
      "DejaVuSans" => { # Using DejaVuSans because it provides the 'filled_check_box' and the 'check_box' icons.
        :bold => "#{Rails.root}/public/data/fonts/DejaVuSans-Bold.ttf",
        :bold_italic => "#{Rails.root}/public/data/fonts/DejaVuSans-BoldOblique.ttf",
        :italic => "#{Rails.root}/public/data/fonts/DejaVuSans-Oblique.ttf",
        :normal => "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"
      }
    )
    font "DejaVuSans"
    self.font_size = 9

    #check_box = "\xE2\x98\x90"
    #filled_check_box = "\xE2\x98\x91"

    ap = ApplicationProfile.first
    current_instance = (ap && ap.sub_title) || Rails.root.to_s.split('/')[3].split('-').first
    ap_logo = ap && ap.logo && ap.logo.path
    fallback_logo = Dir.glob("public/assets/logos/#{current_instance.split('-').first}*", File::FNM_CASEFOLD).first
    logo = ap_logo || "#{Rails.root}/#{fallback_logo}"
    image logo, position: :right, width: 150 if logo
    text "#{current_instance.upcase}", size: 14, style: :bold

    move_down 10

    banner = questionnaire.header.path
    if banner.present? && File.exist?(banner)
      image banner, :position => :left, :width => 550
    end

    move_down 20

    authorization = AuthorizedSubmitter.find_by_questionnaire_id_and_user_id(questionnaire.id, user.id)
    I18n.locale = authorization.language
    questionnaire_field = ( questionnaire.questionnaire_fields.find_by_language(authorization.language) || questionnaire.questionnaire_fields.find_by_is_default_language(true) )
    text "#{questionnaire_field.title.html_safe}", :size => 16, :style => :bold
    #text "Language: #{questionnaire.language_english_name}"

    move_down 18

    text "#{OrtSanitize.white_space_cleanse(questionnaire_field.introductory_remarks).gsub("\n", "\n\n")}", :inline_format => true

    start_new_page

    fields = {}

    puts "#{Time.now} - Started generating #{short_version ? "short" : ""} PDF for - #{questionnaire_field.title} - for #{user.full_name}"
    logger.info "#{Time.now} - Started generating #{short_version ? "short" : ""} PDF for - #{questionnaire_field.title} - for #{user.full_name}"

    begin
      sections = questionnaire.sections
      sections.each_with_index do |section, i|
        fields.clear
        section.objects_fields_in authorization.language, fields
        answers = section.section_and_descendants_answers_for(user).select{ |ans| ans.filled_answer? }
        root_section_to_pdf(authorization.language, section, user, fields, answers, url_prefix, short_version)

        # new page for every new root section (if we're doing a short_version pdf only add the new page if the answers aren't empty)
        # the last check on the if is related with checking if there is any content for the next page
        if i < sections.size-1 && (!short_version || !answers.empty?) && page.content.stream !="/DeviceRGB cs\n0.000 0.000 0.000 scn\n/DeviceRGB CS\n0.000 0.000 0.000 SCN\nq\n" && cursor != 720.0
          # puts "the cursor is here #{cursor}"
          start_new_page
        end
      end

      #footer [ margin_box.left, margin_box.bottom + 25 ] do
      repeat(:all, :dynamic => true) do
        draw_text "#{questionnaire_field.title} [#{user.full_name}, #{user.country}]", :size => 7, :at => [0, -15]
        draw_text "Page #{page_number} of #{page_count}", :size => 8, :at => [500, (questionnaire.title.size > 50 ? -6 : -15)]
      end

      pdf_file = questionnaire.pdf_files.find_by_user_id_and_is_long(user.id, !short_version) || PdfFile.new(:questionnaire => questionnaire, :user => user, :is_long => !short_version)
      if !pdf_file.new_record? && File.exist?(pdf_file.location)
        FileUtils.rm(pdf_file.location)
      end

      sanitized_title = questionnaire.title[0,35].strip.
        gsub!(/[^0-9A-Za-z.\-]/, '_')

      pdf_file.name = "#{sanitized_title}_#{short_version ? "short" : "long"}_#{DateTime.now.strftime("%d%m%Y")}.pdf"
      location_rel = "private/questionnaires/#{questionnaire.id}/users/#{user.id}/"
      location_abs = "#{Rails.root}/#{location_rel}"
      if !File.directory? location_abs
        FileUtils.mkdir_p(location_abs)
      end
      pdf_file.location = location_rel + pdf_file.name
      pdf_file.save
      render_file pdf_file.location

      if File.directory?("#{Rails.root}/private/questionnaires/#{questionnaire.id}/users/#{user.id}/generating_#{short_version ? "short" : "long"}_pdf")
        FileUtils.rmdir("#{Rails.root}/private/questionnaires/#{questionnaire.id}/users/#{user.id}/generating_#{short_version ? "short" : "long"}_pdf")
      end

      puts "#{Time.now.to_s} - PDF Successfully generated - #{questionnaire_field.title} - for #{user.full_name}"
      logger.info "#{Time.now.to_s} - PDF Successfully generated - #{questionnaire_field.title} - for #{user.full_name}"

    rescue => e
      UserMailer.pdf_generation_failed(requester, user, questionnaire, e.message).deliver

      logger.info "#{Time.now.to_s} - PDF failed to generate - #{questionnaire_field.title} - for #{user.full_name} - with error: #{e.message}"
      logger.info e.backtrace

      if File.directory?("#{Rails.root}/private/questionnaires/#{questionnaire.id}/users/#{user.id}/generating_#{short_version ? "short" : "long"}_pdf")
        FileUtils.rmdir("#{Rails.root}/private/questionnaires/#{questionnaire.id}/users/#{user.id}/generating_#{short_version ? "short" : "long"}_pdf")
      end

      return
    end

    # mail the requester about the pdf being generated. (can be the user or an admin)
    UserMailer.pdf_generated(requester, questionnaire, user).deliver
  end

  def root_section_to_pdf language, section, user, fields, answers, url_prefix, short_version
    loop_sources_items = {}
    #multiplier = 1
    if section.looping?
      loop_items = section.loop_item_type.loop_items
      loop_items.each do |loop_item|
        if section.available_for? user, loop_item
          loop_sources_items[section.loop_source.id.to_s] = loop_item
          section_to_pdf  language, section, user, fields, answers, url_prefix, short_version, loop_sources_items, loop_item, loop_item.id.to_s
        end
      end
    else
      section_to_pdf language, section, user, fields, answers, url_prefix, short_version, loop_sources_items#, nil, nil
    end
    loop_sources_items.clear
  end

  ###
  # user: the current user , or the user whose questionnaire is being converted to pdf
  # section: the section that is being treated
  # answers: all the answers of the user for this questionnaire
  # loop_item: current loop_item, in case this is a looping section, nil if there's not one
  # loop_sources_items: hash to keep track of which item was last used  for each loop_source
  def section_to_pdf language, section, user, fields, answers, url_prefix, short_version, loop_sources_items, loop_item=nil, looping_identifier=nil
    #don't print anything for this section if it's a short version and there are no answers for this particular section
    return if short_version && (answers.empty? || !section.any_answers_from?(user, loop_sources_items, loop_item, looping_identifier))
    conditions_met_or_inexistent = section.depends_on_option.present? ? section.dependency_condition_met?(user, looping_identifier) : true
    #If section is hidden and is a looping section and the loop_item is present, print the loop_item name since there is no drop down list like in the Web Sumbission page
    if section.is_hidden? && section.looping? && loop_item.present?
      text "#{loop_item.item_name(language)}", :size => 11, :style => :bold, :inline_format => true
    end
    if !section.is_hidden?
      field_to_use = fields[:sections_field][section.id.to_s] && fields[:sections_field][section.id.to_s].title.present? ? fields[:sections_field][section.id.to_s] : fields[:sections_field_default][section.id.to_s]
      size_to_print = section.root? ? 14 : 11
      if section.looping? && loop_item.present?
        text "#{OrtSanitize.white_space_cleanse(field_to_use.loop_title(nil, loop_item))}", :size => size_to_print, :style => :bold, :inline_format => true
      else
        text "#{OrtSanitize.white_space_cleanse(field_to_use.title)}", :size => size_to_print, :style => :bold, :inline_format => true
      end
      field_to_use = fields[:sections_field][section.id.to_s] && fields[:sections_field][section.id.to_s].description.present? ? fields[:sections_field][section.id.to_s] : fields[:sections_field_default][section.id.to_s]
      images_urls = []
      if field_to_use && field_to_use.description.present?
        #text "#{Sanitize.clean(field_to_use.description)}"
        text "#{OrtSanitize.white_space_cleanse((section.section_extras.present? && loop_item.present?) ?  field_to_use.replace_variables(:description, language, loop_sources_items, loop_item, images_urls) : field_to_use.description)}", :size => 10, :inline_format => true
      end
      display_images images_urls unless images_urls.empty?
      move_down 7
    end
    section.questionnaire_part.children_parts_sorted.each do |child|
      if child.is_a?(Question)
        answer = conditions_met_or_inexistent ? Question.get_answer(answers, child.id, looping_identifier) : nil
        unless short_version && answer.nil?
          question_to_pdf language, child, answer, loop_item, fields, loop_sources_items, url_prefix, short_version
        end
      else
        #if children is of looping type
        if child.looping?
          #get the items through which it is going to loop on
          items = child.next_loop_items loop_item, loop_sources_items
          #for each of the items"
          items.each do |item|
            #check if the section is available for the user
            if child.available_for? user, item
              #update the loop_sources history.
              loop_sources_items[child.loop_source.id.to_s] = item
              new_looping_identifier = looping_identifier ? "#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}#{item.id}" : item.id.to_s
              #call the function for the children, sending the necessary items.
              section_to_pdf language, child, user, fields, answers, url_prefix, short_version, loop_sources_items, item, new_looping_identifier
            end
          end
        else
          #if it is not a looping item just call the function and send the same items...
          section_to_pdf language, child, user, fields, answers, url_prefix, short_version, loop_sources_items, loop_item, looping_identifier
        end
      end
    end
    if section.looping? && section.section_extras.present? && cursor != 720.0
      start_new_page# if section.looping? && section.section_extras.present?
      #puts "the cursor is here #{cursor}"
    end
  end

  def question_to_pdf language, question, answer, loop_item, fields, loop_sources_items, url_prefix, short_version
    #question.short_title + "- " +
    field_to_use = fields[:questions_field][question.id.to_s] && fields[:questions_field][question.id.to_s].title.present? ? fields[:questions_field][question.id.to_s] : fields[:questions_field_default][question.id.to_s]
    text "#{OrtSanitize.white_space_cleanse(( ( question.loop_item_types.present? && loop_item.present? ) ? field_to_use.loop_title(loop_sources_items, loop_item) : field_to_use.title ))}", :size => 10, :inline_format => true
    field_to_use = fields[:questions_field][question.id.to_s] && fields[:questions_field][question.id.to_s].description.present? ? fields[:questions_field][question.id.to_s] : fields[:questions_field_default][question.id.to_s]
    #image_urls is a variable to store the existing urls for extra_fields of type image, to display separately from the description.
    images_urls = []
    #it is necessary to check if field_to_use exists, because questions' description is not mandatory.
    #so the default_object might not have it. and the field_to_use can be nil
    if field_to_use && field_to_use.description.present?
      move_down 5
      text "#{OrtSanitize.white_space_cleanse((question.question_extras.present? && loop_item.present?) ?  field_to_use.replace_variables(:description, language, loop_sources_items, loop_item, images_urls) : field_to_use.description)}", :size => 9, :inline_format => true
    end
    display_images images_urls unless images_urls.empty?
    if question.answer_type
      case question.answer_type_type
      when "MultiAnswer", "RangeAnswer"
        display_multi_or_range_answer question.answer_type, answer, fields, short_version
      when "NumericAnswer"
        display_numeric_answer answer
      when "RankAnswer"
        display_rank_answer question.answer_type, answer, fields
      when "TextAnswer"
        display_text_answer question.answer_type, answer, short_version
      when "MatrixAnswer"
        display_matrix_answer question.answer_type, answer, fields
      end
    end
    if answer
      if answer.documents.present?
        text "#{I18n.t('submission_pages.files_you_have')}"
        move_down 4
        answer.documents.each do |document|
          document = document.doc.exists? ? document : document.original
          next unless document
          #text "<color rgb='#104E8B'><u><a target='_blank' href='#{url_prefix + document.doc.url.split('?')[0]}'>#{document.doc_file_name}</a></u></color>  #{document.description.present? ? "- #{document.description}" : " "}", :inline_format => true
          text "<u><a target='_blank' href='#{url_prefix + document.doc.url.split('?')[0]}'>#{document.doc_file_name}</a></u>  #{document.description.present? ? "- #{document.description}" : ""}", :inline_format => true
          move_down 2
        end
        move_down 3
      end
      if answer.answer_links.present?
        text "#{I18n.t('submission_pages.links_you_have')}"
        move_down 4
        answer.answer_links.each do |link|
          #text "<color rgb='#104E8B'><u><a target='_blank' href='#{link.url}'>#{link.title.blank? ? link.url : link.title}</a></u></color> #{link.description.present? ? "- #{link.description}" : "."}", :inline_format => true
          text "<u><a target='_blank' href='#{link.url}'>#{link.title.blank? ? link.url : link.title}</a></u> #{link.description.present? ? "- #{link.description}" : ""}", :inline_format => true
          move_down 2
        end
        move_down 3
      end
    end
    move_down 5
  end

  #If short version is true only the options, details fields and 'other' options, that are selected or filled will be displayed
  def display_multi_or_range_answer answer_type, answer, fields, short_version
    if !short_version && (answer_type.is_a?(MultiAnswer) && answer_type.single) || answer_type.is_a?(RangeAnswer)
      text "Please select only one option", :size => 8, :style => :italic
    end
    #get all the options ids from the answer's answer_parts
    if answer.present?
      options_selected = answer.answer_parts.map{ |a| a.field_type_id }
    else
      options_selected = []
    end
    answer_type.send(answer_type.class.to_s.underscore.downcase+"_options").sort.each do |mao|
      if !short_version || options_selected.include?(mao.id)
        text "#{options_selected.include?(mao.id) ? FILLED_CHECK_BOX : CHECK_BOX} #{fields[(answer_type.class.to_s.underscore.downcase+"_option_field").to_sym][mao.id.to_s]}"
        #display any details if it's a MultiAnswerOption in which the user added details
        if mao.is_a?(MultiAnswerOption) && mao.details_field? && (!short_version || answer.answer_parts.find_by_field_type_id(mao.id).details_text.present?)
          move_down 5
          text_field 500, 40, options_selected.include?(mao.id) ? answer.answer_parts.find_by_field_type_id(mao.id).details_text : ''
        end
      end
    end
    if answer_type.is_a?(MultiAnswer) && answer_type.other_required && (!short_version || (answer.present? && answer.other_text.present?))
      text "#{(answer.present? && answer.other_text.present?) ? FILLED_CHECK_BOX : CHECK_BOX} #{ fields[:other_text_fields][answer_type.id.to_s]}"#Other:"
      move_down 5
      text_field 500, 40, answer.try(:other_text)
    end
    move_down 5
  end

  def display_rank_answer answer_type, answer, fields
    if answer_type.maximum_choices != -1
      text "Please select only #{answer_type.maximum_choices}", :size => 8, :style => :italic
      move_down 5
    end
    selection = answer ? answer.answer_parts.sort : []
    displayed = []
    selection.each do |part|
      text "(#{part.sort_index+1}) #{fields[:rank_answer_option_field][part.field_type_id.to_s]}"
      displayed << part.field_type_id
    end
    move_down 5
    answer_type.rank_answer_options.each do |option|
      unless displayed.include?(option.id)
        text "( ) #{fields[:rank_answer_option_field][option.id.to_s]}"
      end
    end
    move_down 5
  end

  def display_numeric_answer answer
    if answer.present?
      entered_answer = answer.answer_parts.first
    else
      entered_answer = nil
    end
    text_field 500, 20, entered_answer.try(:answer_text)
    move_down 5
  end

  def display_text_answer answer_type, answer, short_version
    answer_type.text_answer_fields.each do |taf|
      if answer.present?
        entered_answer = answer.answer_parts.find_by_field_type_id(taf.id)
      else
        entered_answer = nil
      end
      the_width = taf.width && taf.width < 50 ? taf.width*10 : 500
      if short_version
        if entered_answer
          the_height = string_height(entered_answer.answer_text)*20
          txt = @coder.decode(entered_answer.try(:answer_text))
          text_field the_width, the_height, txt #entered_answer should always exist for a short version, otherwise it wouldn't get here
        end
      else
        answer_height = entered_answer ? string_height(entered_answer.answer_text) : 0
        the_height = ( [1, taf.rows || 0, answer_height].max ) * 20
        txt = @coder.decode(entered_answer.try(:answer_text))
        text_field the_width, the_height, txt
      end
      move_down 5
    end
  end

  def string_height the_string
    count = 0
    if the_string
      the_string.lines.each do |ls|
        count += 1
        if (ls.size/120) > 1
          count = count + (ls.size/120).ceil
        end
      end
    end
    count
  end

  def display_matrix_answer answer_type, answer, fields
    queries_as_rows = (answer_type.matrix_orientation == 0)
    columns_source = queries_as_rows ? answer_type.matrix_answer_options : answer_type.matrix_answer_queries
    header = [""] + columns_source.map{ |a| (queries_as_rows ? fields[:matrix_answer_option_field][a.id.to_s] : fields[:matrix_answer_query_field][a.id.to_s]) }
    data = []
    rows_source = queries_as_rows ? answer_type.matrix_answer_queries : answer_type.matrix_answer_options
    selection = {}
    if answer
      #get the existing responses for each cell of the matrix
      answer.matrix_cells_answers(selection)
    end
    #set the matrix body
    rows_source.each do |row|
      line = []
      line << (queries_as_rows ? fields[:matrix_answer_query_field][row.id.to_s] : fields[:matrix_answer_option_field][row.id.to_s])
      columns_source.each do |column|
        case answer_type.display_reply
        when 0..1
          checked = queries_as_rows ? (selection[row.id.to_s] ? selection[row.id.to_s].key?(column.id.to_s) : false ) : ( selection[column.id.to_s] ? selection[column.id.to_s].key?(row.id.to_s) : false)
          line << (checked ? FILLED_CHECK_BOX : CHECK_BOX)
        when 2
          existing_text = queries_as_rows ? (selection[row.id.to_s] ? selection[row.id.to_s][column.id.to_s] : "") : (selection[column.id.to_s] ? selection[column.id.to_s][row.id.to_s] : "")
          line << (existing_text.present? ? existing_text : "")
        when 3
          selected = queries_as_rows ? (selection[row.id.to_s] ? selection[row.id.to_s][column.id.to_s] : nil) : (selection[column.id.to_s] ? selection[column.id.to_s][row.id.to_s] : nil )
          drop_down_options = ""
          answer_type.matrix_answer_drop_options.each do |madop|
            drop_down_options << "#{selected && selected.include?(madop.id) ? FILLED_CHECK_BOX : CHECK_BOX} #{fields[:matrix_answer_drop_option_field][madop.id.to_s]}\n"
          end
          line << drop_down_options
        end
      end
      data << line
    end
    case answer_type.display_reply
    when 1
      text "Please select only one per #{queries_as_rows ? "line" : "column."}", :size => 8, :style => :italic
    when 3
      text "Please select only one per square.", :size => 8, :style => :italic
    end
    move_down 10
    font_size 7
    table([header] + data) do
      row(0).style(:font_style => :bold, :background_color => 'cccccc')
      #cells.style(:font_size => 7)
      columns(0).style(:width => 100)
    end
    font_size 9
    move_down 5
  end

  def display_images images_urls
    images_urls.each do |img|
      if img.match(/(.*)\.(jpe?g|png)$/)
        begin
          image open("#{img}"), :position => :left, :height => 100
          move_down 5
        rescue => e
          puts "There was an error with this image #{img}: #{e.message}"
          # continue with the rest
        end
      end
    end
  end

  def text_field box_width, box_rows, entered_text
    #bounding_box [5, cursor], :width => box_width, :height => box_rows do
    span(box_width) do
      if entered_text
        txt = @coder.decode(OrtSanitize.white_space_cleanse(entered_text, false))
        text "››› " + txt
      else
        text "›››"
      end
    end
    #end
  end

  def preview_pdf questionnaire
    font_families.update(
      "DejaVuSans" => {
      :bold => "#{Rails.root}/public/data/fonts/DejaVuSans-Bold.ttf",
      :bold_italic => "#{Rails.root}/public/data/fonts/DejaVuSans-BoldOblique.ttf",
      :italic => "#{Rails.root}/public/data/fonts/DejaVuSans-Oblique.ttf",
      :normal => "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"
    }
    )
    font "DejaVuSans"
    self.font_size = 9
    #check_box = "\xE2\x98\x90"
    text "Questionnaire: #{questionnaire.title}", :size => 14, :style => :bold
    text "Language: #{questionnaire.language_english_name}"
    move_down 20
    questionnaire.questionnaire_parts.sort{ |a,b| a.lft <=> b.lft }.each do |questionnaire_part|
      questionnaire_part.self_and_descendants.sort{ |a,b| a.lft <=> b.lft }.map{ |a| a.part }.each do |part|
        if part.is_a?(Section)
          if !part.is_hidden?
            text "#{OrtSanitize.white_space_cleanse(part.title)}", :size => 11, :style => :bold
            if part.description.present?
              text "#{OrtSanitize.white_space_cleanse(part.description)}", :size => 11
            end
          end
        elsif part.is_a?(Question)
          text "#{OrtSanitize.white_space_cleanse(part.title)}", :style => :bold_italic
          if part.description.present?
            text "#{OrtSanitize.white_space_cleanse(part.description)}"
          end
          move_down 5
          if part.answer_type
            case part.answer_type_type
            when "MultiAnswer", "RangeAnswer"
              if (part.answer_type.is_a?(MultiAnswer) && part.answer_type.single) || part.answer_type.is_a?(RangeAnswer)
                text "Please select only one option", :size => 8, :style => :italic
              end
              part.answer_type.send(part.answer_type.class.to_s.underscore.downcase+"_options").sort.each do |mao|
                text "#{CHECK_BOX} #{mao.option_text}"
              end
              move_down 5
              if part.answer_type.is_a?(MultiAnswer) && part.answer_type.other_required
                text "Other:"
              end
            when "RankAnswer"
              if part.answer_type.maximum_choices != -1
                text "Please select a maximum of #{part.answer_type.maximum_choices} options", :size => 8, :style => :italic
              end
              part.answer_type.rank_answer_options.each do |rao|
                text "( ) #{rao.option_text}"
              end
            when "TextAnswer"
              part.answer_type.text_answer_fields.each do |taf|
                the_width = taf.width && taf.width < 50  ? taf.width * 10 : 500
                the_height = taf.rows ? taf.rows * 20 : 20
                text_field the_width, the_height, nil
              end
            when "NumericAnswer"
              text_field 500, 20, nil
            when "MatrixAnswer"
              preview_matrix_display part.answer_type
            end
          end
          move_down 10
        end
      end
    end
    repeat(:all, :dynamic => true) do
      draw_text "Page #{page_number} of #{page_count}", :size => 8, :at => [500, -15]
    end
    render
  end

  def preview_matrix_display answer_type
    queries_as_rows = (answer_type.matrix_orientation == 0)
    columns_source = queries_as_rows ? answer_type.matrix_answer_options.map{ |a| a.title } : answer_type.matrix_answer_queries.map{ |a| a.title }
    header = [""] + columns_source
    data = []
    rows_source = queries_as_rows ? answer_type.matrix_answer_queries.map{ |a| a.title } : answer_type.matrix_answer_options.map{ |a| a.title }
    rows_source.each do |row|
      line = []
      line << row
      columns_source.each do ||
        case answer_type.display_reply
        when 0..1
          line << CHECK_BOX
        when 2
          line << ""
        when 3
          drop_down_options = ""
          answer_type.matrix_answer_drop_options.each do |madop|
            drop_down_options << "#{CHECK_BOX} #{madop.option_text}\n"
          end
          line << drop_down_options
        end
      end
      data << line
    end
    case answer_type.display_reply
    when 1
      text "Please select only one per #{queries_as_rows ? "line" : "column."}", :size => 8, :style => :italic
    when 3
      text "Please select only one per square.", :size => 8, :style => :italic
    end
    move_down 10
    font_size 7
    table([header] + data) do
      row(0).style(:font_style => :bold, :background_color => 'cccccc')
      #cells.style(:font_size => 7)
      columns(0).style(:width => 65)
    end
    font_size 9
    move_down 5
  end
end
