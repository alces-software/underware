# frozen_string_literal: true

require 'commands'
require 'utils'
require 'filesystem'
require 'shared_examples/asset_command_that_assigns_a_node'

RSpec.describe Metalware::Commands::Asset::Add do
  # Stops the editor from running the bash command
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  it 'errors if the type does not exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-type',
                                   'name',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::InvalidInput)
  end

  context 'when using the default type' do
    before do
      FileSystem.root_setup(&:with_asset_types)
    end

    let(:type) { 'rack' }
    let(:save) { 'saved-asset' }

    let(:type_path) { Metalware::FilePath.asset_type(type) }
    let(:save_path) do
      Metalware::FilePath.asset(type.pluralize, save)
    end

    def run_command(asset_name = save)
      Metalware::Utils.run_command(described_class,
                                   type,
                                   asset_name,
                                   stderr: StringIO.new)
    end

    it 'calls for the type to be opened and copied' do
      expect(Metalware::Utils::Editor).to receive(:open_copy)
        .with(type_path, save_path)
      run_command
    end

    it 'errors if the asset already exists' do
      run_command
      expect do
        run_command
      end.to raise_error(Metalware::InvalidInput)
               .with_message(/already exists/)
    end

    it 'errors if the asset name is an asset type' do
      expect do
        run_command(type)
      end.to raise_error(Metalware::InvalidInput)
               .with_message(/is not a valid/)
    end
  end

  context 'with a node argument' do
    before { FileSystem.root_setup(&:with_asset_types) }

    let(:asset_name) { 'asset1' }
    let(:command_arguments) { ['rack', asset_name] }

    it_behaves_like 'asset command that assigns a node'
  end
end
