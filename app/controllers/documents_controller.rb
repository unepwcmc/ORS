class DocumentsController < ApplicationController

  def show
    answer = Answer.find(params[:answer_id], :include => :questionnaire)
    raise CanCan::AccessDenied.new("You are not authorized to download this document", :show, Document) if answer.questionnaire.private_documents && !current_user # answer.user != current_user || answer.last_editor != current_user
    document = answer.documents.find(params[:id])
    send_file document.doc.path, :type => document.doc_content_type
  end
end
