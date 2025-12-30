# Synchronization helper to mirror remote repos locally for Redmine.
# Keeps a bare mirror in a provider/namespace/path directory structure.
# frozen_string_literal: true

require "fileutils"
require "open3"

module ScmAdapter
  module Mirror
    class Sync
      def initialize(mirror_root:, provider:, remote_full_path:, clone_url:, git_binary: "git", ssl_verify: true, ca_file: nil)
        @mirror_root = mirror_root.to_s
        @provider = provider
        @remote_full_path = remote_full_path
        @clone_url = clone_url
        @git = git_binary.presence || "git"
        @ssl_verify = ssl_verify
        @ca_file = ca_file.presence
      end

      def mirror_path
        File.join(@mirror_root, @provider, "#{@remote_full_path}.git")
      end

      def sync!
        FileUtils.mkdir_p(File.dirname(mirror_path))
        if File.directory?(File.join(mirror_path, ".git")) || File.directory?(mirror_path)
          run_git(["-C", mirror_path, "fetch", "--all", "--prune"])
        else
          run_git(["clone", "--mirror", @clone_url, mirror_path])
        end
        mirror_path
      end

      private

      def run_git(args)
        env = {}
        env["GIT_SSL_NO_VERIFY"] = "1" unless @ssl_verify
        env["GIT_SSL_CAINFO"] = @ca_file if @ca_file
        stdout, stderr, status = Open3.capture3(env, @git, *args)
        return if status.success?

        msg = [stderr, stdout].reject(&:blank?).join("\n")
        raise "git #{args.join(' ')} failed: #{msg}"
      end
    end
  end
end
