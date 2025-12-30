# frozen_string_literal: true

class AddDeletedFieldsToCommitEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :scm_adapter_commit_events, :deleted_at, :datetime
    add_column :scm_adapter_commit_events, :deleted_by_id, :integer
    add_column :scm_adapter_commit_events, :deletion_reason, :text

    add_index :scm_adapter_commit_events, :deleted_at
  end
end
