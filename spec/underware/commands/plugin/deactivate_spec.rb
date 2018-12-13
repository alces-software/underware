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

require 'underware/spec/alces_utils'

RSpec.describe Underware::Commands::Plugin::Deactivate do
  include Underware::AlcesUtils

  def run_plugin_deactivate(plugin_name)
    Underware::Utils.run_command(
      Underware::Commands::Plugin::Deactivate, plugin_name
    )
  end

  let(:filesystem) do
    FileSystem.setup do |fs|
      fs.mkdir_p example_plugin_dir
    end
  end

  let(:example_plugin_dir) do
    File.join Underware::FilePath.plugins_dir, example_plugin_name
  end
  let(:example_plugin_name) { 'example' }

  def example_plugin
    Underware::Plugins.all.find do |plugin|
      plugin.name == example_plugin_name
    end
  end

  it 'switches the plugin to be deactivated' do
    filesystem.test do
      expect(example_plugin).to be_activated

      run_plugin_deactivate(example_plugin_name)

      expect(example_plugin).not_to be_activated
    end
  end

  it 'does not duplicate deactivated plugin if already deactivated' do
    filesystem.test do
      run_plugin_deactivate(example_plugin_name)
      run_plugin_deactivate(example_plugin_name)

      matching_deactivated_plugins = Underware::Plugins.all.select do |plugin|
        !plugin.activated? && plugin.name == example_plugin_name
      end
      expect(matching_deactivated_plugins.length).to eq 1
    end
  end

  it 'gives error if plugin does not exist' do
    filesystem.test do
      unknown_plugin_name = 'unknown_plugin'

      expect do
        Underware::AlcesUtils.redirect_std(:stderr) do
          run_plugin_deactivate(unknown_plugin_name)
        end
      end.to raise_error Underware::UnderwareError,
                         "Unknown plugin: #{unknown_plugin_name}"
    end
  end
end