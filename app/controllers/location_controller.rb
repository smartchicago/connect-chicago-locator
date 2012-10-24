class LocationController < ApplicationController
  before_filter :authenticate_admin!, :except => [:index, :show, :showImage]
  caches_page :showImage

  def index
    @locations = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']};")
  end

  def show
    expire_page :action => :showImage

    @location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    
    respond_to do |format|
      format.html  # show.html.haml
      format.json  { render :json => @location }
    end
  end

  def showImage
    require 'open-uri'
    location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    featured_photo = getFlickrFeaturedPhoto(location[:flickr_tag])
    unless featured_photo.nil?
      url = URI.parse(getFlickrPhotoPath(featured_photo, params[:size]))
      open(url) do |http|
        response = http.read
        render :text => response, :status => 200, :content_type => 'image/jpeg'
      end
    else
      send_data File.read("#{Rails.root}/app/assets/images/placeholder.jpg", :mode => "rb"), :status => 200, :content_type => 'image/jpeg'
    end
  end

  def showWidget
    @location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    
    respond_to do |format|
      format.html  { render :template => "location/widget", :layout => false }
      format.json  { render :json => @location }
    end
  end
  
  def new
  end

  def create
  end

  def edit
    location_edit = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    @location_title = location_edit[:organization_name]
    @location = Location.new(location_edit)
  end

  def update
    # fetch the existing data from Fusion Tables (this it probably redundant)
    location_edit = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    @location_title = location_edit[:organization_name]

    # stuff in new values from the form in to the Fusion Table hash object
    change = {}
    params[:location].each do |name, value|
      old_value = "#{location_edit["#{name}".to_sym]}"
      # if a field has changed, add it to the change hash for location_changes tracking
      if old_value != value
        change["#{name}"] = [old_value, value]
        location_edit["#{name}".to_sym] = value
      elsif old_value == '' && value == ''
        location_edit.delete("#{name}".to_sym)
      end
    end

    # special logic for un-editable fields
    location_edit[:org_phone] = location_edit[:org_phone].gsub /[^0-9x]/, ''
    location_edit[:full_address] = "#{location_edit[:address]} #{location_edit[:city]}, #{location_edit[:state]} #{location_edit[:zip_code]}"
    
    # geocode lat/lng
    require 'geocoder'
    lat, long = Geocoder.coordinates(location_edit[:full_address]) 
    location_edit[:latitude] = "#{lat}"
    location_edit[:longitude] = "#{long}"

    # urls
    location_edit[:website] = add_http location_edit[:website]
    location_edit[:training_url] = add_http location_edit[:training_url]

    @location = Location.new(location_edit)
    if @location.valid? && change.length > 0

      # save to location_changes tracking table
      @location_changes = LocationChanges.new(:admin_id => current_admin.id,
                                                :location_id => @location.id,
                                                :name => @location.organization_name,
                                                :slug => @location.slug,
                                                :change => change.to_json)
      @location_changes.save

      begin
        table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")
        row_id = FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first[:rowid]
        table.update row_id, location_edit

        flash[:notice] = "Location saved successfully!"
      rescue
        flash[:notice] = "There was a problem saving this location. Please try again or contact the system administrator."
      end
      redirect_to "/location/#{params[:id]}"
    else
      render :action => 'edit'
    end
  end

  def destroy
  end

  private

  def add_http url
    if not (url.nil? || url == '')
      if not url.match(/^https?:\/\//)
        url = 'http://' + url
      end
    end
    url
  end
end
