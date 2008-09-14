class CreateUserFailures < ActiveRecord::Migration
  def self.up
    create_table :user_failures do |t|
      t.string :remote_ip, :http_user_agent, :failure_type, :username
      t.integer :count, :default => 0
      t.timestamps
    end

    add_index :user_failures, :remote_ip
  end

  def self.down
    drop_table :user_failures
  end
end
