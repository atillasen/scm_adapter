# frozen_string_literal: true
class CreateScmAdapterIntegrationSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :scm_adapter_integration_settings do |t|
      t.integer :project_id
      t.string  :provider, null: false # gitlab/github
      t.string  :base_url, null: false
      t.text    :token_encrypted
      t.string  :webhook_secret

      t.timestamps
    end
    add_index :scm_adapter_integration_settings, [:project_id, :provider], unique: true, name: "idx_scm_integrations_project_provider"
  end
end
