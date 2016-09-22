class SourceFilesController < ApplicationController

  def edit
    @source_file = SourceFile.find(params[:id], :include => {:loop_source => :questionnaire})
  end

  def update
    @source_file = SourceFile.find(params[:id])
    if @source_file.update_attributes(params[:source_file])
      #@source_file.loop_source.parse_loop_source_files current_user.id, current_user.current_login_ip
      ParseLoopSourceFiles.perform_async(current_user.id, current_user.current_login_ip, @source_file.loop_source.id)
      flash[:notice] = "Successfully updated source file."
      redirect_to @source_file.loop_source
    else
      flash[:error] = "There was an error updating the source file details."
      redirect_to @source_file
    end
  end

  def destroy
    source_file = SourceFile.find(params[:id])
    @loop_source = source_file.loop_source
    source_file.destroy
    flash[:notice] = "Source file successfully destroyed"
    redirect_to @loop_source
  end
end
