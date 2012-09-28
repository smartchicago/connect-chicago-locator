class LocationController < ApplicationController
  def show
    @location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE Slug = '#{params[:slug]}';").first
    
    respond_to do |format|
      format.html  # show.html.haml
      format.json  { render :json => @location }
    end
  end

  def showImage
    require 'open-uri'
    location = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} WHERE Slug = '#{params[:slug]}';").first
    featured_photo = getFlickrFeaturedPhoto(location[:flickr_tag])
    unless featured_photo.nil?
      url = URI.parse(getFlickrPhotoPath(featured_photo))
      open(url) do |http|
        response = http.read
        render :text => response, :status => 200, :content_type => 'image/jpeg'
      end
    else
      url = URI.parse('http://www.neurillion.com/p/35/static/media/images/1x1t.gif')
      open(url) do |http|
        response = http.read
        render :text => response, :status => 200, :content_type => 'image/gif'
      end
    end
  end
end
