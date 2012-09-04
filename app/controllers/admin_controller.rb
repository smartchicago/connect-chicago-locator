class AdminController < ApplicationController
  before_filter :authenticate_admin!

  def index
		if current_admin.try(:superadmin?)
			if params[:approved] == "false"
			  @admins = Admin.find_all_by_approved(false)
			else
			  @admins = Admin.all
			end
	  end
	end

	def show
		@admin = Admin.find(params[:id])
	end

	def new

	end

	def create

	end

	def edit

	end

	def update

	end

	def destroy

	end

end
