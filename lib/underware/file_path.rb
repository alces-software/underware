# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Underware.
#
# Alces Underware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Underware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Underware, please visit:
# https://github.com/alces-software/underware
#==============================================================================

require 'underware/constants'
require 'underware/file_path/config_path'

module Underware
  module FilePath
    class << self
      delegate :domain_config,
               :group_config,
               :node_config,
               :local_config,
               :config_dir,
               to: :config_path

      def genders_template
        File.join(templates_dir, 'genders')
      end

      def templates_dir
        File.join(internal_data_dir, 'templates')
      end

      def configure_file
        File.join(internal_data_dir, 'configure.yaml')
      end

      def domain_answers
        File.join(answer_files, 'domain.yaml')
      end

      def group_answers(group)
        file_name = "#{group}.yaml"
        File.join(answer_files, 'groups', file_name)
      end

      def node_answers(node)
        file_name = "#{node}.yaml"
        File.join(answer_files, 'nodes', file_name)
      end

      def local_answers
        node_answers('local')
      end

      def answer_files
        File.join(underware_storage, 'answers')
      end

      def overview
        File.join(internal_data_dir, 'overview.yaml')
      end

      def plugins_dir
        File.join(underware_storage, 'plugins')
      end

      def build_complete(node_namespace)
        event(node_namespace, 'complete')
      end

      def define_constant_paths
        Constants.constants
                 .map(& :to_s)
                 .select { |const| /\A.+_PATH\Z/.match?(const) }
                 .each do |const|
                   method_name = :"#{const.chomp('_PATH').downcase}"
                   define_singleton_method method_name do
                     Constants.const_get(const)
                   end
                 end
      end

      def event(node_namespace, event = '')
        File.join(events_dir, node_namespace.name, event)
      end

      def log
        '/var/log/underware'
      end

      def asset_type(type)
        File.join(underware_install, 'data/asset_types', type + '.yaml')
      end

      def asset(*a)
        record(asset_dir, *a)
      end

      def asset_dir
        File.join(underware_storage, 'assets')
      end

      def layout(*a)
        record(layout_dir, *a)
      end

      def layout_dir
        File.join(underware_storage, 'layouts')
      end

      def asset_cache
        File.join(cache, 'assets.yaml')
      end

      def cached_template(name)
        File.join(cache, 'templates', name)
      end

      def namespace_data_file(name)
        File.join(
          Constants::NAMESPACE_DATA_PATH,
          "#{name}.yaml"
        )
      end

      def internal_data_dir
        File.join(underware_install, 'data')
      end

      private

      def record(record_dir, types_dir, name)
        File.join(record_dir, types_dir, name + '.yaml')
      end

      def template_file_name(template_type, namespace:)
        namespace.config.templates&.send(template_type) || 'default'
      end

      def config_path
        ConfigPath.new(base: internal_data_dir)
      end
    end
  end
end

Underware::FilePath.define_constant_paths
