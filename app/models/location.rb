class Location
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  validates_presence_of :organization_name, :organization_type, :org_phone, :address, :city, :state, :zip_code
  # validates_format_of :agency_staff_person_contact_email, :location_leadership_email, :pcc_staff_person_email, 
  #                     :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i,
  #                     :allow_nil => true, :allow_blank => true

  def create_method( name, &block )
    self.class.send( :define_method, name, &block )
  end

  def create_attr( name )
    create_method( "#{name}=".to_sym ) { |val| 
      instance_variable_set( "@" + name, val)
    }

    create_method( name.to_sym ) { 
      instance_variable_get( "@" + name ) 
    }
  end
  
  
  def [](attr)
    self.send(attr)
  end

  def []=(attr, val)
    create_attr(attr.to_s) unless respond_to?(attr)  # initialize new attrs on the fly
    self.send("#{attr}=", val)
  end
  
  def initialize(attributes = {})
    #read in a hash of attributes from Fusion Tables and set them as attributes of the model
    #for more, see http://railscasts.com/episodes/219-active-model
    attributes.each do |name, value|
      name = "#{name}"
      create_attr name
      instance_variable_set("@" + name.to_s, value)
    end
  end
  
  def to_fusion_format
    # return the object as a hash, suitable for saving to Google Fusion Tables
    self.instance_variables.inject({}) do |memo, v|
      k = v.to_s.gsub(/@/, '')
      memo[k.to_sym] = send(k)
      memo
    end
  end
  
  def create
    table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")
    column_names = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} LIMIT 1;").first.collect{|k,v| k }    
    new_values = self.to_fusion_format.delete_if{ |k,v| !column_names.include?(k) }    
    table.insert new_values #saves to Fusion Tables    
  end
  
  def save
    # save the record to Fusion Tables
    table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")
    row_id = FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{slug}';").first[:rowid]
    column_names = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} LIMIT 1;").first.collect{|k,v| k }
    
    new_values = self.to_fusion_format.delete_if{ |k,v| !column_names.include?(k) }
    table.update row_id, new_values  # saves to Fusion Tables
  end
  
  def persisted?
    false
  end
  
  def self.all    
    collection = []
    results = Rails.cache.fetch("all-locations", :expires_in => 12.hours) do
      FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']} ORDER BY organization_name;")
    end
    
    results.each do |result|
      collection << Location.new(result)
    end
    collection
  end
end