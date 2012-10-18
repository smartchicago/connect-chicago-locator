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
    @ft_location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
    puts @ft_location.inspect
    @location = Location.new(@ft_location)
  end

  def update
    puts params[:location]
    @location_update = Location.new(params[:location])
    if @location_update.valid?

      table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")

      location_save = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first
      row_id = FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{params[:id]}';").first[:rowid]
      
      params[:location].each do |name, value|
        unless location_save["#{name}".to_sym].nil?
          location_save["#{name}".to_sym] = value
        end
      end
      
      puts location_save.inspect

      table.update row_id, location_save

      flash[:notice] = "Location saved successfully!"
      redirect_to "/location/#{params[:id]}"
    else
      render :action => 'edit'
    end
  end

  def destroy
  end
end
