# frozen_string_literal: true

class CreateScmAdapterCommitEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :scm_adapter_commit_events do |t|
      t.bigint :issue_id, null: false
      t.string :provider, null: false
      t.string :sha, limit: 100
      t.string :author
      t.string :url
      t.text :message
      t.datetime :pushed_at

      t.timestamps
    end

    add_index :scm_adapter_commit_events, :issue_id
    add_index :scm_adapter_commit_events, %i[provider sha]
  end
end
