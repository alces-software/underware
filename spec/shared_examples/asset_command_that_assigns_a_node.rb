
# frozen_string_literal: true

require 'underware/spec/alces_utils'
require 'underware/cache/asset'

# Requires `asset_name` and `command_arguments` to be set by the
# calling spec
RSpec.shared_examples 'asset command that assigns a node' do
  include Underware::AlcesUtils

  # Stops the editor from running the bash command
  before { allow(Underware::Utils::Editor).to receive(:open) }

  let(:asset_cache) { Underware::Cache::Asset.new }
  let(:node_name) { 'test-node' }

  def run_command
    Underware::Utils.run_command(described_class,
                                 *command_arguments,
                                 node: node_name,
                                 stderr: StringIO.new)
  end

  context 'when the node is missing' do
    it 'raise an invalid input error' do
      expect { run_command }.to raise_error(Underware::InvalidInput)
    end
  end

  context 'when the node exists' do
    let!(:node) { Underware::AlcesUtils.mock(self) { mock_node(node_name) } }

    it 'assigns the asset to the node' do
      run_command
      expect(asset_cache.asset_for_node(node)).to eq(asset_name)
    end
  end
end
