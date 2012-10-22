class LocationChangesController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @location_changes = LocationChanges.order("created_at DESC")
  end
end
