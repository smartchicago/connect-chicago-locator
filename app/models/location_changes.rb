class LocationChanges < ActiveRecord::Base
  attr_accessible :admin_id, :location_id, :name, :slug, :change, :created_at
  belongs_to :admin
end
