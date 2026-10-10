class AddMailingTimestampsToInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :invites, :save_the_date_sent_at, :datetime
    add_column :invites, :invitation_sent_at, :datetime
  end
end
