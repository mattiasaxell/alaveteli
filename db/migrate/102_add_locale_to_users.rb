# -*- encoding : utf-8 -*-
class AddLocaleToUsers < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_column :users, :locale, :string
  end
  def self.down
    remove_column :users, :locale
  end
end
