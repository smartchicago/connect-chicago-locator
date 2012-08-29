class AdminController < ApplicationController
  def index
    if params[:approved] == "false"
      @admins = Admin.find_all_by_approved(false)
    else
      @admins = Admin.all
    end
  end
end
