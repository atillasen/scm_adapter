# frozen_string_literal: true

class AddMergeRequestFieldsToCommitEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :scm_adapter_commit_events, :merge_request_title, :string, limit: 255
    add_column :scm_adapter_commit_events, :merge_request_url, :string, limit: 500
    add_column :scm_adapter_commit_events, :merge_request_iid, :string, limit: 50
  end
end
