# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
puts 'Superadmin Roles'

%w(superadmin admin).each do |role|
  SuperAdminRole.find_or_create_by(name: role)
end

puts 'Default superadmin'

unless SuperAdmin.find_by(email: 'admin@example.com')
  user = SuperAdmin.create(username: 'admin', email: 'admin@example.com', password: 'password')
  user.add_role :superadmin
end

company = FactoryGirl.create :company
manager = FactoryGirl.create :manager
agent = FactoryGirl.create :agent
service_channel = FactoryGirl.create :service_channel
