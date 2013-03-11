class LocationController < ApplicationController
  before_filter :authenticate_admin!, :except => [:index, :show, :showImage, :showWidget]
  before_filter :set_location, :only => [:show, :edit]
  # caches_action :showImage
  caches_action :show, :layout => false
  caches_action :index, :layout => false

  def index
    @locations = Location.all
  end

  def show
    respond_to do |format|
      format.html  # show.html.haml
      format.json  { render :json => @location }
    end
  end

  def showImage
    require 'open-uri'
    location = fetch params[:id]
    featured_photo = getFlickrFeaturedPhoto(location.flickr_tag)
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
    @location = fetch params[:id]
    
    respond_to do |format|
      format.html  { render :template => "location/widget", :layout => false }
      format.json  { render :json => @location }
    end
  end
  
  def new
    location_edit = fetch_empty
    @location = Location.new(location_edit)
  end

  def create
    @location = Location.new(params[:location])
    
    # location_edit = fetch_empty
    @location = set_changes(@location, params)

    # fill in read-only values
    # FIXME: move to model
    @location[:id] = get_new_id
    @location[:slug] = to_slug "#{@location[:organization_name]} #{@location[:address]}"
    @location[:flickr_tag] = to_flickr_tag "pcc-#{@location[:organization_name]} #{@location[:id]}"
    
    # FT has some problems with empty fields. clearing them out
    # @location.each do |name, value|
    #   if value == ''
    #     location_edit.delete("#{name}".to_sym)
    #   end
    # end
    
    if @location.valid?
       # expire cache
       expire_action :action => :index

      # save to location_changes tracking table
      save_location_changes({"Location created" => ""})

      begin
        @location.create
        flash[:notice] = "Location created successfully!"
      rescue StandardError => e
        flash[:notice] = "There was a problem creating this location. Please try again or contact the system administrator."
        Rails.logger.error("[LocationController#create] error saving new item: #{e.message}")
        Rails.logger.error("[LocationController#create] error message:\n\n #{e.backtrace.join("\n")}")                
      end
      redirect_to location_path :id => @location.slug
    else
       render :action => 'new'
    end

  end

  def edit
    @location_title = @location[:organization_name]
  end

  def update
    # fetch the existing data from Fusion Tables (this it probably redundant)
    @location = fetch params[:id]
    @location_title = @location[:organization_name]

    # stuff in new values from the form in to the Fusion Table hash object
    change = {}
    params[:location].each do |name, value|
      old_value = "#{@location["#{name}".to_sym]}"
      # if a field has changed, add it to the change hash for location_changes tracking
      if old_value != value
        change["#{name}"] = [old_value, value]
      end
    end

    @location = set_changes(@location, params)

    Rails.logger.debug 'changes!'
    Rails.logger.debug change.inspect
    if @location.valid? && change.length > 0
      # expire cache
      expire_action :action => :show
      expire_action :action => :index

      # save to location_changes tracking table
      save_location_changes(change)

      begin
        @location.save # saves to Fusion Tables
        flash[:notice] = "Location saved successfully!"
      rescue StandardError => e
        Rails.logger.error("[LocationController#update] error saving update: #{e.message}")
        Rails.logger.error("[LocationController#update] error message:\n\n #{e.backtrace.join("\n")}")        
        flash[:notice] = "There was a problem saving this location. Please try again or contact the system administrator."
      end
      redirect_to location_path :id => @location.slug
    else
      render :action => 'edit'
    end
  end

  def destroy
    if current_admin.try(:superadmin?)
      expire_action :action => :show
      expire_action :action => :index

      begin
        @location = fetch params[:id]
        # save to location_changes tracking table
        save_location_changes({"Location deleted" => ""})

        table = fetch_table
        row_id = fetch_row_id @location.slug
        table.delete row_id
        flash[:notice] = "Location deleted successfully!"
        redirect_to root_path
      rescue
        flash[:notice] = "There was a problem deleting this location. Please try again or contact the system administrator."
        redirect_to location_path :id => @location.slug
      end
    else
      flash[:notice] = "You must be a super admin to delete locations."
      redirect_to location_path :id => @location.slug
    end
  end

  private

  def fetch_table
    GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")
  end

  def fetch_empty
    # fetch a row to get the column names and set to blank
    location_edit = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} LIMIT 1;").first || not_found
    location_edit.each do |k, v|
      location_edit[k] = ''
    end
    location_edit
  end

  def fetch(slug)
    location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{slug}';").first
    location.present? ? Location.new(location) : nil
  end

  def fetch_row_id(slug)
    FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{slug}';").first[:rowid]
  end

  def set_location
    @location = fetch(params[:id]) || not_found
    @page_title = @location.organization_name
  end

  def set_changes(location_edit, params)
    # stuff in new values from the form in to the Fusion Table hash object
    params[:location].each do |name, value|
      old_value = "#{location_edit["#{name}".to_sym]}"
      # if a field has changed, add it to the change hash for location_changes tracking
      if old_value != value
        location_edit.send("#{name}=", value)
      elsif old_value == '' && value == ''
        # location_edit.delete("#{name}".to_sym)
      end
    end

    # special logic for un-editable fields
    if location_edit[:org_phone] != nil and location_edit[:org_phone] != ''
      location_edit[:org_phone] = location_edit[:org_phone].gsub /[^0-9x]/, ''
    end
    location_edit[:full_address] = "#{location_edit[:address]} #{location_edit[:city]}, #{location_edit[:state]} #{location_edit[:zip_code]}"
    
    # geocode lat/lng
    if location_edit[:full_address] != nil and location_edit[:full_address] != ''
      require 'geocoder'
      lat, long = Geocoder.coordinates(location_edit[:full_address]) 
      location_edit[:latitude] = "#{lat}"
      location_edit[:longitude] = "#{long}"
    end

    # urls
    location_edit[:website] = add_http location_edit[:website]
    location_edit[:training_url] = add_http location_edit[:training_url]

    location_edit
  end

  def save_location_changes(changes)
    @location_changes = LocationChanges.new(:admin_id => current_admin.id,
                                              :location_id => @location.id,
                                              :name => @location.organization_name,
                                              :slug => @location.slug,
                                              :change => changes.to_json)
    @location_changes.save
  end

  def get_new_id
    id = FT.execute("SELECT id FROM #{APP_CONFIG['fusion_table_id']} ORDER BY id DESC LIMIT 1;").first[:id]
    id.to_i + 1
  end

  def add_http url
    if not (url.nil? || url == '')
      if not url.match(/^https?:\/\//)
        url = 'http://' + url
      end
    else
      url = ''
    end
    url
  end

  def to_slug s
    #strip the string
    ret = s.strip.downcase

    #blow away apostrophes
    ret.gsub! /['`.]/,""

    # @ --> at, and & --> and
    ret.gsub! /\s*@\s*/, " at "
    ret.gsub! /\s*&\s*/, " and "

    #replace all non alphanumeric, underscore or periods with underscore
     ret.gsub! /\s*[^A-Za-z0-9\.\-]\s*/, '-'  

     #convert double underscores to single
     ret.gsub! /_+/,"_"

     #strip off leading/trailing underscore
     ret.gsub! /\A[_\.]+|[_\.]+\z/,""

     ret
  end

  def to_flickr_tag(s)
    n = 3 #num words 
    s = s.split[0...n].join(' ')
    #strip the string
    ret = s.strip.downcase

    #blow away apostrophes
    ret.gsub! /['`.]/,""

    # @ --> at, and & --> and
    ret.gsub! /\s*@\s*/, " at "
    ret.gsub! /\s*&\s*/, " and "

    #replace all non alphanumeric, underscore or periods with underscore
     ret.gsub! /\s*[^A-Za-z0-9\.\-]\s*/, '-'  

     #convert double underscores to single
     ret.gsub! /_+/,"_"

     #strip off leading/trailing underscore
     ret.gsub! /\A[_\.]+|[_\.]+\z/,""

     ret
  end
end
