class ApplicationController < ActionController::Base
  protect_from_forgery
  # before_filter :authenticate

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, with: lambda { |exception| render_error 500, exception }
    rescue_from ActionController::RoutingError, ActionController::UnknownController, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound, with: lambda { |exception| render_error 404, exception }
  end

  private
  def render_error(status, exception)
    ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    Rails.logger.fatal "[FATAL] #{exception.message}\n\nBacktrace:\n\n#{exception.backtrace.join(%Q(\n))}"

    respond_to do |format|
      format.html { render template: "errors/error_#{status}", layout: 'layouts/application', status: status }
      format.all { render nothing: true, status: status }
    end
  end

  #TODO: move these flickr functions to a more appropriate place
  helper_method :getFlickrGalleryPhotos
  helper_method :getFlickrFeaturedPhoto
  helper_method :getFlickrPhotoPath
  
  def getFlickrGalleryPhotos tags, count=14
    list = flickr.photos.search(:tags => tags, :safe_search => "1", :per_page => count)
    if list.length > 0
      list
    else
      []
    end
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

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  protected
  def authenticate
    if Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        username == ENV['AUTH_USERNAME'] && password == ENV['AUTH_PASS']
      end
    end
  end

  # private
  # #set default redirect after logging in
  # def after_sign_in_path_for(admin)
  #   admins_path
  # end
end
