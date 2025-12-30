# frozen_string_literal: true

module ScmAdapter
  module Patches
    module RepositoriesHelperPatch
      # Render file tree for a changeset but compact Java package paths
      # (segments after src/main/java are joined with dots and shown as one node).
      def render_changeset_changes
        changes = @changeset.filechanges.limit(1000).reorder("path").filter_map do |change|
          case change.action
          when "A"
            if change.from_path.present?
              change.action = @changeset.filechanges.detect { |c| c.action == "D" && c.path == change.from_path } ? "R" : "C"
            end
            change
          when "D"
            @changeset.filechanges.detect { |c| c.from_path == change.path } ? nil : change
          else
            change
          end
        end

        tree = {}
        changes.each do |change|
          p = tree
          segments = compact_java_segments(change.path)
          path = ""
          segments.each do |segment|
            label = nil
            segment_path = segment
            if segment.is_a?(Hash)
              label = segment[:label]
              segment_path = segment[:path]
            end

            path += "/" + segment_path.to_s
            p[:s] ||= {}
            p = p[:s]
            p[path] ||= {}
            p[path][:label] = label if label
            p = p[path]
          end
          p[:c] = change
        end
        render_changes_tree(tree[:s])
      end

      def render_changes_tree(tree)
        return "" if tree.nil?

        output = +""
        output << "<ul>"
        tree.keys.sort.each do |file|
          style = +"change"
          label = tree[file][:label] || File.basename(h(file))

          if (s = tree[file][:s])
            style << " folder"
            path_param = to_path_param(@repository.relative_path(file))
            text = link_to(h(label), { controller: "repositories",
                                      action: "show",
                                      id: @project,
                                      repository_id: @repository.identifier_param,
                                      path: path_param,
                                      rev: @changeset.identifier })
            output << "<li class='#{style}'>#{text}"
            output << render_changes_tree(s)
            output << "</li>"
          elsif (c = tree[file][:c])
            style << " change-#{c.action}"
            path_param = to_path_param(@repository.relative_path(c.path))
            text = link_to(h(label), { controller: "repositories",
                                      action: "entry",
                                      id: @project,
                                      repository_id: @repository.identifier_param,
                                      path: path_param,
                                      rev: @changeset.identifier }) unless c.action == "D"
            text ||= h(label)
            text << " - #{h(c.revision)}" unless c.revision.blank?
            text << " (".html_safe + link_to(l(:label_diff), { controller: "repositories",
                                                               action: "diff",
                                                               id: @project,
                                                               repository_id: @repository.identifier_param,
                                                               path: path_param,
                                                               rev: @changeset.identifier }) + ") ".html_safe if c.action == "M"
            text << " ".html_safe + content_tag("span", h(c.from_path), class: "copied-from") unless c.from_path.blank?
            output << "<li class='#{style}'>#{text}</li>"
          end
        end
        output << "</ul>"
        output.html_safe
      end

      private

      def compact_java_segments(path)
        segments = path.to_s.split("/").reject(&:blank?)
        java_idx = segments.index("java")
        return segments unless java_idx && java_idx < segments.size - 1

        filename = segments.pop
        package_parts = segments[(java_idx + 1)..-1]
        return segments + [filename] if package_parts.empty?

        compact_label = package_parts.join(".")
        compact_path = (segments + package_parts).join("/")

        segments[0..java_idx] + [{ label: compact_label, path: compact_path }] + [filename]
      end
    end
  end
end

RepositoriesHelper.prepend ScmAdapter::Patches::RepositoriesHelperPatch
