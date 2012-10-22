class Location
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  #attr_accessor :id, :organizationname
  
  validates_presence_of :organization_name, :organization_type, :org_phone, :address, :city, :state, :zip_code
  validates_format_of :agency_staff_person_contact_email, :location_leadership_email, :pcc_staff_person_email, 
                      :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i,
                      :allow_nil => true, :allow_blank => true
  # validates_length_of :content, :maximum => 500


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
  
  def initialize(attributes = {})
    #read in a hash of attributes from Fusion Tables and set them as attributes of the model
    #for more, see http://railscasts.com/episodes/219-active-model
    attributes.each do |name, value|
      name = "#{name}"
      create_attr name
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end
end