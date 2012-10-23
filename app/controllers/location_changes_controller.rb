class LocationChangesController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @location_changes = LocationChanges.paginate(:page => params[:page], :per_page => 10).order("created_at DESC")
  end
end
