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
    location_edit = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    @location_title = location_edit[:organization_name]

    params[:location].each do |name, value|
      unless location_edit["#{name}".to_sym].nil?
        location_edit["#{name}".to_sym] = value
      end
    end

    @location = Location.new(location_edit)
    #puts "valid? #{@location.valid?}"
    if @location.valid?

      table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")
      row_id = FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first[:rowid]
      table.update row_id, location_edit

      flash[:notice] = "Location saved successfully!"
      redirect_to "/location/#{params[:id]}"
    else
      puts @location.errors.messages.inspect
      render :action => 'edit'
    end
  end

  def destroy
  end
end
