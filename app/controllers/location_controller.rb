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

    # puts 'parameters'
    # puts params[:location]

    # stuff in new values from the form in to the Fusion Table hash object
    require 'json'
    change = {}
    params[:location].each do |name, value|
      if value != '' && location_edit["#{name}".to_sym] != value
        change["#{name}"] = [location_edit["#{name}".to_sym], value]
      end
      location_edit["#{name}".to_sym] = value
    end

    # strange hack! FT was complaining about empty fields on UPDATE
    # TODO: fix this so values can be set back to empty
    # throwing away the values that are empty
    location_edit.each do |name, value|
      if location_edit["#{name}".to_sym] == ''
        location_edit.delete("#{name}".to_sym)
      end
    end

    # special logic for un-editable fields
    location_edit[:org_phone] = location_edit[:org_phone].gsub /[^0-9x]/, ''

    location_edit[:full_address] = "#{location_edit[:address]} #{location_edit[:city]}, #{location_edit[:state]} #{location_edit[:zip]}"
    
    #if address changed, geocode lat/lng
    require 'geocoder'
    lat, long = Geocoder.coordinates(location_edit[:full_address]) 
    location_edit[:latitude] = "#{lat}"
    location_edit[:longitude] = "#{long}"

    # urls
    location_edit[:website] = add_http location_edit[:website]
    location_edit[:training_url] = add_http location_edit[:training_url]


    @location = Location.new(location_edit)
    if @location.valid?

      # save to location_changes tracking table
      if change.length > 0
        @location_changes = LocationChanges.new(:admin_id => current_admin.id,
                                                :location_id => @location.id,
                                                :name => @location.organization_name,
                                                :slug => @location.slug,
                                                :change => change.to_json)
        @location_changes.save
      end

      # puts "new location data"
      # puts location_edit.inspect

      table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")
      row_id = FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first[:rowid]
      table.update row_id, location_edit

      flash[:notice] = "Location saved successfully!"
      redirect_to "/location/#{params[:id]}"
    else
      #puts @location.errors.messages.inspect
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
