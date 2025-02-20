class ActsAsXapianMigration < ActiveRecord::Migration[4.2] # 2.0
  def self.up
    create_table :acts_as_xapian_jobs do |t|
      t.column :model, :string, null: false
      t.column :model_id, :integer, null: false

      t.column :action, :string, null: false
    end
    add_index :acts_as_xapian_jobs, [:model, :model_id], unique: true

    remove_index :info_requests, :solr_up_to_date
    remove_column :info_requests, :solr_up_to_date

    InfoRequest.find_each do |i|
      i.calculate_event_states
      STDERR.puts "calculate_event_states " + i.id.to_s
    end
  end

  def self.down
    drop_table :acts_as_xapian_jobs

    add_column :info_requests, :solr_up_to_date, :boolean, default: false, null: false
    add_index :info_requests, :solr_up_to_date
  end
end
