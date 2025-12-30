# Hinweis: Redmine installiert Plugins nicht als Gems; dieses Gemspec dient Doku/Dev.
require_relative "lib/scm_adapter/version"

Gem::Specification.new do |spec|
  spec.name          = "scm_adapter"
  spec.version       = ScmAdapter::VERSION
  spec.authors       = ["Atilla Sen"]
  spec.email         = ["home@atilla-sen.com"]

  spec.summary       = "Redmine-Plugin: SCM-Integration (GitLab/GitHub) mit Sync & Webhooks"
  spec.description   = "Synchronisiert Issues/Status/Referenzen zwischen Redmine und GitLab/GitHub. Mit Sidekiq, Webhooks, Test-Buttons."
  spec.homepage      = "https://atilla-sen.com/scm_adapter"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["{app,config,db,lib,test}/**/*", "README.md", "LICENSE-APACHE-2.0.txt", "NOTICE", "init.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.10"
  spec.add_dependency "faraday-retry"
  spec.add_dependency "multi_json"
  spec.add_dependency "sidekiq", "~> 7.2"
  spec.add_dependency "redis", "~> 5.3"
end
