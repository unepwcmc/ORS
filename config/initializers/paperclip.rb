Paperclip.interpolates :questionnaire_id do |attachment, style|
  "questionnaire_" + attachment.instance.questionnaire.id.to_s
end
Paperclip.interpolates :user_id do |attachment, style|
  "user_" + attachment.instance.user.id.to_s
end
Paperclip.interpolates :answer_id do |attachment, style|
  attachment.instance.answer.id.to_s
end
Paperclip.interpolates :loop_source_id do |attachment, style|
  attachment.instance.id.to_s
end
