class LocationController < ApplicationController
  caches_page :showImage

  def index
    @locations = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']};")
  end

  def show
    expire_page :action => :showImage

    @location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE Slug = '#{params[:id]}';").first
    
    respond_to do |format|
      format.html  # show.html.haml
      format.json  { render :json => @location }
    end
  end

  def showImage
    require 'open-uri'
    location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE Slug = '#{params[:id]}';").first
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

  before_filter :authenticate_admin!
  
  def new
  end

  def create
    # @location = Location.new(params[:location])
    # if @location.valid?
    #   # TODO send message here
    #   flash[:notice] = "Location saved successfully!"
    #   redirect_to "/location/#{@location[:slug]}"
    # else
    #   render :action => 'new'
    # end
  end

  def edit
    @ft_location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE Slug = '#{params[:id]}';").first
    @location = Location.new(@ft_location)
  end

  def update
    puts params[:location]
    @location = Location.new(params[:location])
    if @location.valid?
      # TODO send message here
      flash[:notice] = "Location saved successfully!"
      redirect_to "/location/#{@location.id}"
    else
      render :action => 'edit'
    end
  end

  def destroy
  end
end
