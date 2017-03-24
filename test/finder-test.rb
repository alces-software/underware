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

require "alces/stack/finder"

class TC_Templater_Finder < Test::Unit::TestCase
  def setup
    @default_kickstart_repo = "#{ENV['alces_REPO']}"
    @default_kickstart_path = "/kickstart"
    @default_kickstart = "#{@default_kickstart_repo}/#{@default_kickstart_path}".gsub(/\/\/+/, "/")
    @default_boot_repo = "#{ENV['alces_REPO']}"
    @diff_repo = "/var/lib/metalware/repos/new-repo"
    @default_boot_path = "/boot"
    @default_boot = "#{@default_boot_repo}/#{@default_boot_path}".gsub(/\/\/+/, "/")
    @tmp_folder = "#{@default_kickstart}/tempfolderthatshouldnotexist"
    @tmp_folder2 = "#{@diff_repo}#{@default_boot_path}"
    @tmp_file = "#{@tmp_folder}/local.erb"
    @tmp_file2 = "#{@default_kickstart}/local-boot.erb"
    @tmp_file3 = "#{@default_kickstart}/local_boot.erb"
    @diff_repo_temp = "new-repo-template.erb"
    `mkdir #{@tmp_folder}`
    `mkdir -p #{@tmp_folder2}` 
    `echo "A whole bunch of nothing" > #{@tmp_file}`
    `echo "A whole bunch of nothing" > #{@tmp_file2}`
    `echo "A whole bunch of nothing" > #{@tmp_file3}`
    `echo "A whole bunch of nothing" > #{@tmp_folder2}/#{@diff_repo_temp}`
  end

  def teardown 
    `rm -rf #{@tmp_folder}`
    `rm -rf #{@tmp_folder2}`
    `rm -f #{@tmp_file2}`
    `rm -f #{@tmp_file3}`
  end

  def test_find_kickstart
    fullpath  = "#{@default_kickstart}/compute.erb"
    tmp_fullpath  = "#{@default_kickstart}/local.erb"
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "#{@default_kickstart}/compute.erb")
    assert_equal(fullpath, find.template, "Could not find file from full path")
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "#{@default_kickstart}/compute")
    assert_equal(fullpath, find.template, "Could not find file from full path with no .ext")
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "/compute.erb")
    assert_equal(fullpath, find.template, "Could not find file from name")
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "compute")
    assert_equal(fullpath, find.template, "Could not find file from name no .ext")
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "tempfolderthatshouldnotexist/local.erb")
    assert_equal(@tmp_file, find.template, "Found nested template")
    assert_raise Alces::Stack::Finder::TemplateNotFound do 
        Alces::Stack::Finder.new(@default_kickstart_repo,
                                 @default_kickstart_path,
                                 "local")
    end
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "local-boot")
    assert_equal(@tmp_file2, find.template, "Could not find file with a -")
    find = Alces::Stack::Finder.new(@default_kickstart_repo,
                                    @default_kickstart_path,
                                    "local_boot")
    assert_equal(@tmp_file3, find.template, "Could not find file with a _")
  end

  def test_find_boot
    fullpath = "#{@default_boot}/install.erb"
    find = Alces::Stack::Finder.new(@default_boot_repo, @default_boot_path, "install")
    assert_equal(fullpath, find.template, "Could not find boot template")
  end

  def test_path
    find = Alces::Stack::Finder.new(@default_boot_repo, @default_boot_path, "install")
    assert_equal(@default_boot, find.path, "Did not return correct path to template")
  end

  def test_different_repo
    fullpath = "#{@tmp_folder2}/#{@diff_repo_temp}"
    find = Alces::Stack::Finder.new(@default_boot_repo, @default_boot_path, "new-repo::new-repo-template")
    assert_equal(fullpath, find.template, "Did not return correct path to the different repo")
  end

  def test_repo_not_found
    assert_raise Alces::Stack::Finder::ErrorRepoNotFound do
        Alces::Stack::Finder.new(@diff_repo,
                                 @default_boot_path,
                                 "no-repo::new-repo-template")
    end
    assert_raise Alces::Stack::Finder::ErrorRepoNotFound do
        Alces::Stack::Finder.new(@diff_repo,
                                 @default_boot_path,
                                 "::new-repo-template")
    end
  end

  def test_filename
    find = Alces::Stack::Finder.new(@default_kickstart_repo, @default_kickstart_path, "compute")
    assert_equal("compute", find.filename, "Did not return correct filename or ext")
    assert_equal("compute.erb", find.filename_ext, "Did not return correct filename or ext")
    assert_equal("compute.ks", find.filename_diff_ext("ks"), "Did not return correct filename or ext")
    assert_equal("compute.ks", find.filename_diff_ext(".ks"), "Did not return correct filename or ext")
    assert_equal("compute.ks", find.filename_diff_ext(".ks"), "Did not return correct filename or ext")
    find = Alces::Stack::Finder.new(@default_kickstart_repo, @default_kickstart_path, "local-boot")
    assert_equal("local-boot", find.filename, "Did not find filename with -")
    find = Alces::Stack::Finder.new(@default_kickstart_repo, @default_kickstart_path, "local_boot")
    assert_equal("local_boot", find.filename, "Did not find filename with _")
    assert_raise Alces::Stack::Finder::TemplateNotFound do Alces::Stack::Finder.new(@default_kickstart_repo, @default_kickstart_path, "") end
    assert_raise Alces::Stack::Finder::TemplateNotFound do Alces::Stack::Finder.new(@default_kickstart_repo, @default_kickstart_path, nil) end
  end
end