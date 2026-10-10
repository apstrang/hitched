class AddRsvpTokenToInvites < ActiveRecord::Migration[8.0]
  class MigrationInvite < ActiveRecord::Base
    self.table_name = "invites"
  end

  def up
    add_column :invites, :rsvp_token, :string

    MigrationInvite.reset_column_information
    MigrationInvite.find_each do |invite|
      invite.update_columns(rsvp_token: SecureRandom.base58(24))
    end

    change_column_null :invites, :rsvp_token, false
    add_index :invites, :rsvp_token, unique: true
  end

  def down
    remove_index :invites, :rsvp_token
    remove_column :invites, :rsvp_token
  end
end
