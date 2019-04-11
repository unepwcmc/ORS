class DocumentsController < ApplicationController

  def show
    answer = Answer.find(params[:answer_id], :include => :questionnaire)
    raise CanCan::AccessDenied.new("You are not authorized to download this document", :show, Document) if answer.questionnaire.private_documents && !current_user # answer.user != current_user || answer.last_editor != current_user
    document = answer.documents.find(params[:id])
    # If document doesn't exist in filesystem, this probably means
    # the questionnaire has been cloned from another one and here there's
    # still the original file to be fetched.
    document = document.original unless File.exists?(document.doc.path)
    send_file document.doc.path, :type => document.doc_content_type
  end
end
