class SetUpFirstAdminUser < ActiveRecord::Migration
  def self.up
		#Be sure to change these settings for your initial admin user
    user = User.new
		user.login = "admin"
		user.email = "admin@example.com"
		user.password = "password"
		user.password_confirmation = "password"
    user.save
		role = Role.new
		#Admin role name should be "admin"
		role.name = "admin"
		role.save
		admin_user = User.find_by_login("admin")
		admin_role = Role.find_by_name("admin")
		admin_user.activate!
		admin_user.roles << admin_role
		admin_user.save		
  end

  def self.down
		admin_user = User.find_by_login("admin")
		admin_role = Role.find_by_name("admin")
		admin_user.roles = []
    admin_user.save
    admin_user.destroy
		admin_role.destroy
  end
end
