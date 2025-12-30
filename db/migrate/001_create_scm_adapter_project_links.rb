# frozen_string_literal: true
class CreateScmAdapterProjectLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :scm_adapter_project_links do |t|
      t.integer :project_id, null: false
      t.string  :provider, null: false # "gitlab"|"github"
      t.string  :remote_project_id, null: false
      t.string  :remote_full_path, null: false # "group/name" oder "owner/repo"

      t.timestamps
    end

    add_index :scm_adapter_project_links, [:provider, :remote_full_path], unique: true, name: "idx_scm_links_provider_path"
    add_index :scm_adapter_project_links, :project_id
  end
end

