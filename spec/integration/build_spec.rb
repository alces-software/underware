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

require 'config'
require 'constants'
require 'spec_utils'
require 'system_command'

# TODO: Could test rendering in these tests as well, though already doing in
# unit tests.

RSpec.describe '`metal build`' do
  METAL = File.join(Metalware::Constants::METALWARE_INSTALL_PATH, 'bin/metal')
  TEST_DIR = 'tmp/integration-test'
  CONFIG_FILE = SpecUtils.fixtures_config('integration-test.yaml')
  TEST_CONFIG = Metalware::Config.new(CONFIG_FILE)

  TEST_KICKSTART_DIR = File.join(TEST_CONFIG.rendered_files_path, 'kickstart')
  TEST_PXELINUX_DIR = TEST_CONFIG.pxelinux_cfg_path
  TEST_BUILT_NODES_DIR = TEST_CONFIG.built_nodes_storage_path
  TEST_NODES_ANSWERS_PATH = "tmp/answers"
  TEST_NODES_ANSWER_FILES = ["domain.yaml", "groups/nodes.yaml"]

  TEST_REPO = 'spec/fixtures/minimal-repo/'
  PXELINUX_TEMPLATE = File.join(TEST_REPO, 'pxelinux/default')

  def kill_any_metal_processes
    `pkill bin/metal --full`
  end

  # Refer to http://stackoverflow.com/a/3568291/2620402.
  def process_exists?(pid)
    Process.getpgid(pid)
    true
  rescue Errno::ESRCH
    false
  end

  def wait_longer_than_build_poll
    # Hopefully longer enough than the `build_poll_sleep` that build process
    # notices whatever it needs to.
    sleep 0.6
  end

  def run_command(command, &block)
      Timeout::timeout 5 do
        Open3.popen3 command do |stdin, stdout, stderr, thread|
          begin
            pid = thread.pid
            block.call(stdin, stdout, stderr, pid)
          rescue Exception => e
            begin
              # Try to read output `stdout` and `stderr`, or just ensure original
              # exception raised if not available.
              max_bytes_to_read = 30000
              stdout_data = stdout.read_nonblock(max_bytes_to_read)
              stderr_data = stderr.read_nonblock(max_bytes_to_read)
              puts "stdout:\n#{stdout_data}\n\nstderr:\n#{stderr_data}"
            rescue
              raise e
            end
            raise
          end
        end
    end
  end

  def expect_clears_up_built_node_marker_files
    expect(Dir.empty?(TEST_BUILT_NODES_DIR)).to be true
  end

  before :each do
    kill_any_metal_processes

    ENV['PATH'] = "spec/fixtures/libexec/:#{ENV['PATH']}"

    FileUtils.remove_dir(TEST_DIR, force: true)
    FileUtils.mkdir_p(TEST_KICKSTART_DIR)
    FileUtils.mkdir_p(TEST_PXELINUX_DIR)
    FileUtils.mkdir_p(TEST_BUILT_NODES_DIR)

    unless File.exists? TEST_REPO
      Metalware::SystemCommand.run \
        'git clone https://github.com/alces-software/metalware-default.git tmp/repo'
      # TODO: Once `feature/topologies-changes` is merged into master, a tag
      # should be created to replace the checkout branch. This way the exact branch
      # that is used is insured to be constant, regardless of future changes
      Metalware::SystemCommand.run \
        'cd tmp/repo && git checkout feature/topologies-changes'
    end

    TEST_NODES_ANSWER_FILES.each do |f|
      file = File.join(TEST_NODES_ANSWERS_PATH, f)
      unless File.exists? file
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    end
  end

  after do
    kill_any_metal_processes
  end

  context 'for single node' do
    it 'works' do
      command = "#{METAL} build testnode01 --config #{CONFIG_FILE} --trace"
      run_command(command) do |stdin, stdout, stderr, pid|
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true

        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be false

        expect_clears_up_built_node_marker_files
      end
    end
  end

  context 'for gender group' do
    it 'works' do
      command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
      run_command(command) do |stdin, stdout, stderr, pid|
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true

        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true

        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode02')
        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode03')
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be false

        expect_clears_up_built_node_marker_files
      end
    end

    describe 'interrupt handling' do
      # Initial interrupt does not exit CLI; gives prompt for whether to
      # re-render all Pxelinux configs as if nodes all built.

      def expect_interrupt_does_not_kill(pid)
        Process.kill('INT', pid)
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true
      end

      def expect_interrupt_kills(pid)
        Process.kill('INT', pid)
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be false
      end

      def expect_permanent_pxelinux_rendered_for_testnode01
        testnode01_pxelinux =  File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode01_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(TEST_CONFIG, PXELINUX_TEMPLATE, {
            nodename: 'testnode01', firstboot: false
          })
        )
      end

      def expect_permanent_pxelinux_rendered_for_testnode02
        testnode01_pxelinux =  File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode02_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(TEST_CONFIG, PXELINUX_TEMPLATE, {
            nodename: 'testnode02', firstboot: false
          })
        )
      end

      def expect_firstboot_pxelinux_rendered_for_testnode02
        testnode01_pxelinux =  File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode02_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(TEST_CONFIG, PXELINUX_TEMPLATE, {
            nodename: 'testnode02', firstboot: true
          })
        )
      end

      it 'exits on second interrupt' do
        command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
        run_command(command) do |stdin, stdout, stderr, pid|
          FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be true

          expect_interrupt_does_not_kill(pid)
          expect_interrupt_kills(pid)
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_permanent_pxelinux_rendered_for_testnode02
        end
      end

      it 'handles "yes" to interrupt prompt' do
        command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
        run_command(command) do |stdin, stdout, stderr, pid|
          FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be true

          expect_interrupt_does_not_kill(pid)

          stdin.puts('yes')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be false
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_permanent_pxelinux_rendered_for_testnode02
        end
      end

      it 'handles "no" to interrupt prompt' do
        command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
        run_command(command) do |stdin, stdout, stderr, pid|
          FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be true

          expect_interrupt_does_not_kill(pid)

          stdin.puts('no')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be false
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_firstboot_pxelinux_rendered_for_testnode02
        end
      end
    end
  end
end
