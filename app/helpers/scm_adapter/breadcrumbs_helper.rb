# frozen_string_literal: true

module ScmAdapter
  module BreadcrumbsHelper
    # Shrinks Java package paths by collapsing everything after src/main/java into
    # a single dot-delimited segment. Returns label segments, per-label raw paths,
    # and filename info for building correct URLs without 404.
    def compact_breadcrumbs(path, kind)
      raw_segments = path.to_s.split("/")
      return [raw_segments, [], nil] if raw_segments.empty?

      raw_filename = nil
      # Entferne Datei aus dem Pfad, egal ob kind mitgegeben wurde
      if kind == "file" || raw_segments.last.to_s.include?(".")
        raw_filename = raw_segments.pop
      end

      labels = []
      raw_paths = []

      java_idx = raw_segments.index("java")
      if java_idx && java_idx < raw_segments.length - 1
        raw_segments.each_with_index do |seg, idx|
          if idx == java_idx
            labels << seg
            raw_paths << raw_segments[0..idx].join("/")

            package_parts = raw_segments[(idx + 1)..-1]
            labels << package_parts.join(".")
            raw_paths << raw_segments.join("/")
            break
          else
            labels << seg
            raw_paths << raw_segments[0..idx].join("/")
          end
        end
      else
        raw_segments.each_with_index do |seg, idx|
          labels << seg
          raw_paths << raw_segments[0..idx].join("/")
        end
      end

      [labels, raw_paths, raw_filename]
    end
  end
end
