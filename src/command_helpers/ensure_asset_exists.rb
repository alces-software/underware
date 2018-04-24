# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module EnsureAssetExists
      def post_setup
        super
        error_if_asset_file_does_not_exist(asset_path)
      end

      def error_if_asset_file_does_not_exist(asset_name)
        return if File.exist?(asset_path)
        raise InvalidInput, <<-EOF.squish
          The "#{asset_name}" record does not exist
        EOF
      end
    end
  end
end
