# frozen_string_literal: true

class AddCloneBaseUrlToIntegrationSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :scm_adapter_integration_settings, :clone_base_url, :string
  end
end
