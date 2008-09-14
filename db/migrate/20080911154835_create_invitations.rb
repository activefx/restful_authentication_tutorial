class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table "invitations" do |t|
			t.integer  :sender_id
			t.string   :email, :token
			t.datetime :sent_at
			t.timestamps
    end

    add_index :invitations, :token, :unique => true
  end

  def self.down
    drop_table "invitations"
  end
end
