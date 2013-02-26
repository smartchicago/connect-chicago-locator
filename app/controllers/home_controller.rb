class HomeController < ApplicationController
  def index
  end

  def sitemap
    @locations = Location.all
    respond_to do |format|
      format.xml
    end
  end
end
