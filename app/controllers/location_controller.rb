class LocationController < ApplicationController
  def show
    @location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE Slug = '#{params[:slug]}';").first
    
    respond_to do |format|
      format.html  # show.html.haml
      format.json  { render :json => @location }
    end
  end
end
