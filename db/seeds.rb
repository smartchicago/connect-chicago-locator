puts 'SETTING UP ADMIN USERS'

admin1Email = 'derek.eder@gmail.com'
admin1Pass = 'smartchicago'
admin1First = "Test"
admin1Last = "User"
admin1Org = "Smart Chicago"


if (Rails.env.production?)
	puts 'In production, using ENV credentials'
	admin1Email = ENV['admin1Email'].dup
	admin1Pass = ENV['admin1Pass'].dup
end

admin1 = Admin.create! :first_name => admin1First, :last_name => admin1Last, :organization => admin1Org,  :email => admin1Email, :password => admin1Pass, :password_confirmation => admin1Pass, :location_id => 1

admin1.approved = true
admin1.superadmin = true
admin1.save!
puts 'New user created: ' << admin1.email
