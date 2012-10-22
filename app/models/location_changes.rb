class LocationChanges < ActiveRecord::Base
  attr_accessible :admin_id, :location_id, :change, :created_at
end
