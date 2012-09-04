puts 'SETTING UP ADMIN USERS'

admin1Email = 'test@example.com'
admin1Pass = 'testpass'

if (Rails.env.production?)
	puts 'In production, using ENV credentials'
	admin1Email = ENV['admin1Email'].dup
	admin1Pass = ENV['admin1Pass'].dup
end

admin1 = Admin.create! :email => admin1Email, :password => admin1Pass, :password_confirmation => admin1Pass
admin1.approved = true
admin1.superadmin = true
admin1.save!
puts 'New user created: ' << admin1.email