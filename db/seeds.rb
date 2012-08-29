# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
puts 'SETTING UP ADMIN USERS'
admin1 = Admin.create! :email => 'test@example.com', :password => 'testpass', :password_confirmation => 'testpass', :approved => true
puts 'New user created: ' << admin1.email