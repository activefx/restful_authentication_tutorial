class CreateFourOhFours < ActiveRecord::Migration
  def self.up
    create_table :four_oh_fours do |t|
      t.string :url, :referer
      t.integer :count, :default => 0
      t.timestamps
    end

    add_index :four_oh_fours, [:url, :referer], :unique => true
    add_index :four_oh_fours, [:url]
  end

  def self.down
    drop_table :four_oh_fours
  end
end

