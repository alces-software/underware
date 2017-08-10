
# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'constants'
require 'network'

module Metalware
  class DomainTemplatesRenderer
    def initialize(config, genders_invalid_message: nil)
      @config = config
      @genders_invalid_message = genders_invalid_message
    end

    def render
      render_methods.each do |method|
        rendered_file_invalid = !send(method)
        if rendered_file_invalid
          msg = "An error occurred rendering: #{method.to_s.sub('render_', '')}"
          raise DomainTemplatesInternalError, msg
        end
      end
    end

    private

    attr_reader :config, :genders_invalid_message

    def render_methods
      # These are order dependent, as data used in later methods may depend on
      # earlier files having been rendered successfully.
      [
        :render_metalware_server_config,
        :render_genders,
        :render_hosts,
      ]
    end

    def render_metalware_server_config
      render_template(
        server_config_template,
        to: Constants::SERVER_CONFIG_PATH
      ) do |rendered_config|
        validate_rendered_server_config(rendered_config)
      end
    end

    def validate_rendered_server_config(rendered_config)
      config_data = Data.load_string(rendered_config)
      build_interface = config_data[:build_interface]
      Network.valid_interface?(build_interface).tap do |valid|
        display_server_config_error(build_interface: build_interface) unless valid
      end
    end

    def display_server_config_error(build_interface:)
      interfaces_list = Network.interfaces.join(', ')
      Output.stderr \
        "\nAborting rendering domain templates; the rendered server config is invalid:"
      Output.stderr_indented_error_message \
        "#{build_interface} is not a valid interface; valid interfaces: #{interfaces_list}"
    end

    def render_genders
      render_template(
        genders_template,
        to: Constants::GENDERS_PATH
      ) do |rendered_genders|
        validate_rendered_genders(rendered_genders)
      end
    end

    def validate_rendered_genders(rendered_genders)
      genders_valid, nodeattr_error = validate_genders_using_nodeattr(rendered_genders)
      handle_invalid_genders(rendered_genders, nodeattr_error) unless genders_valid
      genders_valid
    end

    def validate_genders_using_nodeattr(rendered_genders)
      Tempfile.open do |tempfile|
        tempfile.write(rendered_genders)
        tempfile.flush
        NodeattrInterface.validate_genders_file(tempfile.path)
      end
    end

    def handle_invalid_genders(rendered_genders, nodeattr_error)
      cache_invalid_genders(rendered_genders)
      display_genders_error(nodeattr_error)
    end

    def cache_invalid_genders(rendered_genders)
      File.write(Constants::INVALID_RENDERED_GENDERS_PATH, rendered_genders)
    end

    def display_genders_error(nodeattr_error)
      Output.stderr "\nAborting rendering domain templates; " \
        'the rendered genders file is invalid:'
      Output.stderr_indented_error_message(nodeattr_error)
      Output.stderr \
        "The rendered file can be found at #{Constants::INVALID_RENDERED_GENDERS_PATH}"
      Output.stderr "\n" + genders_invalid_message if genders_invalid_message
    end

    def render_hosts
      render_template(hosts_template, to: Constants::HOSTS_PATH)
    end

    def render_template(template, to:, &block)
      Templater.render_to_file(
        config,
        template,
        to,
        prepend_managed_file_message: true,
        &block
      )
    end

    def server_config_template
      File.join(config.repo_path, 'server.yaml')
    end

    def genders_template
      template_path('genders')
    end

    def hosts_template
      template_path('hosts')
    end

    def template_path(template_type)
      # We currently always/only render the 'default' templates.
      File.join(config.repo_path, template_type, 'default')
    end
  end
end
