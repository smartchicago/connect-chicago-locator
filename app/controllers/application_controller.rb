class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate

  #TODO: move these flickr functions to a more appropriate place
  helper_method :getFlickrGalleryPhotos
  helper_method :getFlickrFeaturedPhoto
  helper_method :getFlickrPhotoPath
  
  def getFlickrGalleryPhotos tags, count=14
    list = flickr.photos.search(:tags => tags, :safe_search => "1", :per_page => count)
    list
  end

  def getFlickrFeaturedPhoto tags
    featured_photos = flickr.photos.search(:tags => "#{tags}-featured", :safe_search => "1", 
      :per_page => 1, :user_id => "36521980095@N01")
    if featured_photos.length > 0
      return featured_photos.first
    end
    nil
  end

  def getFlickrPhotoPath photo, size=''
    #see http://www.flickr.com/services/api/misc.urls.html for URL reference
    flickr_size = ""
    unless (size == '' || size.nil?) 
      flickr_size = "_#{size}"
    end
    return "http://farm#{photo.farm}.static.flickr.com/#{photo.server}/#{photo.id}_#{photo.secret}#{flickr_size}.jpg"
  end
  
  protected
  def authenticate
    if Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        username == ENV['AUTH_USERNAME'] && password == ENV['AUTH_PASS']
      end
    end
  end

  private
  #set default redirect after logging in
  def after_sign_in_path_for(admin)
    admins_path
  end
end
