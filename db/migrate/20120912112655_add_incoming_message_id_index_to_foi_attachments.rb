# -*- encoding : utf-8 -*-
class AddIncomingMessageIdIndexToFoiAttachments < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :foi_attachments, :incoming_message_id
  end

  def self.down
    remove_index :foi_attachments, :incoming_message_id
  end
end
