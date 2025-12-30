# frozen_string_literal: true
class ScmAdapter::IntegrationSetting < ActiveRecord::Base
  self.table_name = "scm_adapter_integration_settings"

  belongs_to :project, optional: true

  PROVIDERS = %w[gitlab github].freeze

  validates :provider, inclusion: { in: PROVIDERS }
  validates :base_url, presence: true

  def token=(val)
    write_attribute(:token_encrypted, ScmAdapter::Encryption.encrypt(val))
  end

  def token
    ScmAdapter::Encryption.decrypt(read_attribute(:token_encrypted).to_s)
  end
end
