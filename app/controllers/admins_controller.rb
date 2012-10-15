class AdminsController < ApplicationController
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
		@admin = Admin.find(params[:id])

		#don't allow users to edit/delete their own account while signed in
		if (current_admin.id == @admin.id)
			redirect_to(edit_admin_registration_path, :notice => 'Redirected to your account registration page.')
		end
	end

	def update
		@admin = Admin.find(params[:id])

		#remove the password key of the params hash if it’s blank. If not, Devise will fail to validate
		if params[:admin][:password].blank?
		  params[:admin].delete(:password)
		  params[:admin].delete(:password_confirmation)
		end

    if @admin.update_attributes(params[:admin])
      redirect_to(@admin, :notice => 'Admin was successfully updated.')
    else
      render :action => "edit"
    end
	end

	def approve
    @admin = Admin.find(params[:id])
    
    @admin.approved = 1
    @admin.save

    redirect_to(admins_path, :notice => 'Admin was approved.')
  end

	def destroy
		@admin = Admin.find(params[:id])
	  @admin.destroy
	 
	 	redirect_to(admins_path, :notice => 'Admin was deleted.')
	end

end
