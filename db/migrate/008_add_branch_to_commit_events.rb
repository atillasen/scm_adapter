# frozen_string_literal: true

class AddBranchToCommitEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :scm_adapter_commit_events, :branch, :string, limit: 150
  end
end
