class Location
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  #attr_accessor :id, :organizationname
  
  validates_presence_of :organizationname
  # validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
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
    attributes.each do |name, value|
      name = "#{name}".gsub('?', '')
      create_attr name
      #puts "#{name}: #{value}"
      send("#{name}=", value)
      
    end
  end
  
  def persisted?
    false
  end
end