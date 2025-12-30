# frozen_string_literal: true
# Einfache Verschlüsselung sensibler Tokens in DB (Plugin-Settings-Model),
# nutzt Redmine/Rails secret_key_base.
require "active_support"
require "active_support/message_encryptor"
require "active_support/key_generator"

module ScmAdapter
  module Encryption
    def self.encrypt(plaintext)
      return "" if plaintext.to_s.empty?
      crypt.encrypt_and_sign(plaintext)
    end

    def self.decrypt(ciphertext)
      return "" if ciphertext.to_s.empty?
      crypt.decrypt_and_verify(ciphertext)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      ""
    end

    def self.crypt
      secret = Rails.application.secret_key_base || "fallback-secret"
      salt   = "scm-adapter-token-salt"
      key    = ActiveSupport::KeyGenerator.new(secret).generate_key(salt, 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
