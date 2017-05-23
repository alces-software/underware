
require 'timeout'

require 'commands/build'
require 'node'
require 'spec_utils'


describe Metalware::Commands::Build do
  def run_build(node_identifier, **options_hash)
    # Run command in timeout as `build` will wait indefinitely, but want to
    # abort tests if it looks like this is happening.
    Timeout::timeout 0.5 do
      SpecUtils.run_command(
        Metalware::Commands::Build, node_identifier, **options_hash
      )
    end
  end

  # Makes `Node.new` return real `Node`s, but with certain methods stubbed to
  # not depend on environment.
  def use_mock_nodes(not_built_nodes: [])
    allow(
      Metalware::Node
    ).to receive(:new).and_wrap_original do |original_new, config, name|
      original_new.call(config, name).tap do |node|
        # Stub this as depends on `gethostip` and `/etc/hosts`
        allow(node).to receive(:hexadecimal_ip).and_return(node.name + '_HEX_IP')

        # Stub this to return that node is built, unless explicitly pass in
        # node as not built.
        node_built = !not_built_nodes.include?(node.name)
        allow(node).to receive(:built?).and_return(node_built)
      end
    end
  end

  def expect_runs_longer_than(seconds, &block)
    expect do
      Timeout::timeout(seconds, &block)
    end.to raise_error TimeoutError
  end

  before :each do
    use_mock_nodes
    SpecUtils.use_unit_test_config(self)
  end

  context 'when called without group argument' do
    it 'renders default templates for given node' do
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/default',
        '/var/lib/metalware/rendered/kickstart/testnode01',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', index: 0)
      ).at_least(:once)

      run_build('testnode01')
    end

    it 'uses different templates if template options passed' do
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', index: 0)
      ).at_least(:once)

      run_build(
        'testnode01',
        kickstart: 'my_kickstart',
        pxelinux: 'my_pxelinux'
      )
    end

    it 'renders pxelinux once with firstboot true if node does not build' do
      time_to_wait = 0.2
      use_mock_nodes(not_built_nodes: 'testnode01')

      allow(Metalware::Templater).to receive(:save)
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', firstboot: true)
      ).once

      expect_runs_longer_than(time_to_wait) { run_build('testnode01') }
    end

    it 'renders pxelinux twice with firstboot switched if node builds' do
      allow(Metalware::Templater).to receive(:save)
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', firstboot: true)
      ).once.ordered
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', firstboot: false)
      ).once.ordered

       run_build('testnode01')
    end

  end

  context 'when called for group' do
    before :each do
      SpecUtils.use_mock_genders(self)
    end

    it 'renders templates for each node' do
      allow(Metalware::Templater).to receive(:save)
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode02',
        hash_including(nodename: 'testnode02', index: 1)
      )
      expect(Metalware::Templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode02_HEX_IP',
        hash_including(nodename: 'testnode02', index: 1)
      )

      run_build(
        'testnodes',
        group: true,
        kickstart: 'my_kickstart',
        pxelinux: 'my_pxelinux'
      )
    end
  end

end
