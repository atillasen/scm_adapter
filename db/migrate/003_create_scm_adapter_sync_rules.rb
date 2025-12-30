# frozen_string_literal: true
class CreateScmAdapterSyncRules < ActiveRecord::Migration[6.1]
  def change
    create_table :scm_adapter_sync_rules do |t|
      t.integer :project_id

      # Verwende json für MySQL, jsonb für PostgreSQL
      if connection.adapter_name.downcase.start_with?('mysql')
        # MySQL erlaubt keine Default-Werte auf JSON-Spalten
        t.json  :issue_status_mapping, null: true
        t.json  :close_keywords,       null: true
      else
        t.jsonb :issue_status_mapping, null: false, default: {}
        t.jsonb :close_keywords,       null: false, default: []
      end

      t.timestamps
    end

    add_index :scm_adapter_sync_rules, :project_id
  end
end

