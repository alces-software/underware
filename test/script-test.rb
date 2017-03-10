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
require_relative "#{ENV['alces_BASE']}/test/helper/base-test-require.rb" 

require "alces/stack/templater"
require "alces/stack/iterator"

class TC_Script < Test::Unit::TestCase
  def setup
    @bash = File.read("/etc/profile.d/alces-metalware.sh")
    @base_temp_loc = "#{ENV['alces_BASE']}/etc/templates/script"
    @template = "test.sh"
    @template_str = "<%= nodename %> <%= json %>"
    File.write("#{@base_temp_loc}/#{@template}.erb", @template_str)
    @finder = Alces::Stack::Templater::Finder.new(@base_temp_loc, "#{@template}")
    @single_node = "slave04"
    @single_input_hash = { nodename: @single_node }
    @save_location_base = "/var/lib/metalware/rendered/scripts"
    @save_location =
      "#{@save_location_base}/<%= nodename %>" << "/#{@finder.filename_ext}"
    @json = '{"json" : "json included" }'
  end

  def test_single_dry
    output = 
      `#{@bash} metal script -x -n #{@single_node} -j '#{@json}' -t #{@template}`
    combiner = Alces::Stack::Templater::Combiner.new(@json, @single_input_hash)
    correct = "SCRIPT TEMPLATE\nHash: " << combiner.parsed_hash.to_s
    correct << "\nSave: " << @save_location.gsub("<%= nodename %>", @single_node)
    correct << "\nTemplate:\n" << combiner.file(@finder.template)
    assert_equal(correct, output.chomp, "Dry run output incorrect")
  end

  def test_single
    new_save_loc = "#{@save_location_base}/<%= nodename %>/add/here"
    run_str = "#{@bash} metal script -n #{@single_node} -j '#{@json}' -t " \
              "#{@template} -v --save-location \"#{new_save_loc}\""
    `#{run_str}`
    new_save_loc << "/#{@finder.filename_ext}"
    output = File.read(new_save_loc.gsub("<%= nodename %>", @single_node))
    correct = Alces::Stack::Templater::Combiner.new(@json, @single_input_hash)
                                               .file(@finder.template)
    assert_equal(correct, output.chomp, "Did not save rendered template correctly")
  end

  def test_group
    `#{@bash} metal script -g slave -j '#{@json}' -t #{@template}`
    folders = `ls #{@save_location_base}`.split("\n")
    num_nodes = 
      Alces::Stack::Iterator.run("slave", lambda { |a| return a }, {}).count
    assert_equal(num_nodes, folders.count, "Incorrect number of script folders created")
    folders.each do |f|
      num_files = `ls #{@save_location_base}/#{f}`.split("\n").count
      assert_equal(1, num_files,"Incorrect number of files created")
      output = `cat #{@save_location_base}/#{f}/*`
      correct = Alces::Stack::Templater::Combiner.new(@json, { nodename: f })
                                               .file(@finder.template)
      assert_equal(correct, output.chomp, "Contents of files incorrect")
    end
  end

  def teardown
    `rm -f #{@base_temp_loc}/@template`
    `rm -rf #{@save_location_base}/*`
  end
end