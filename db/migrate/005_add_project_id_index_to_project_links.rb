# frozen_string_literal: true

class AddProjectIdIndexToProjectLinks < ActiveRecord::Migration[6.1]
  def change
    add_index :scm_adapter_project_links, [:provider, :remote_project_id], unique: true, name: "idx_scm_links_provider_remote_id"
  end
end
