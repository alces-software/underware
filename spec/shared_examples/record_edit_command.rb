# frozen_string_literal: true

require 'underware/spec/alces_utils'

RSpec.shared_examples 'record edit command' do
  include AlcesUtils
  # Stop the editor from running the bash command
  before { allow(Underware::Utils::Editor).to receive(:open) }

  it 'errors if the record does not exist' do
    expect do
      Underware::Utils.run_command(described_class,
                                   'missing-record',
                                   stderr: StringIO.new)
    end.to raise_error(Underware::MissingRecordError)
  end

  context 'when using a saved record' do
    def run_command
      Underware::Utils.run_command(described_class,
                                   record_name,
                                   stderr: StringIO.new)
    end

    it 'calls for the record to be opened and copied into a temp file' do
      expect(Underware::Utils::Editor).to receive(:open_copy)
        .with(record_path, record_path)
      run_command
    end
  end
end
