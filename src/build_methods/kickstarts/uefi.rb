
# frozen_string_literal: true
require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class UEFI < Kickstart
        TEMPLATES = [:kickstart, :uefi].freeze

        private

        def pxelinux_repo_dir
          :uefi
        end

        def save_path
          File.join(file_path.uefi_save, "grub.cfg-#{node.hexadecimal_ip}")
        end
      end
    end
  end
end
