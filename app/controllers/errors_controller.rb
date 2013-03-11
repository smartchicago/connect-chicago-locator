class ErrorsController < ApplicationController
  def error_404
    respond_to do |format|
      format.html { @not_found_path = params[:not_found] } 
      format.any  { render :nothing => true, :status => 404 } 
    end
  end

  def error_500
  end
end
