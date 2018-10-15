# frozen_string_literal: true

require 'shared_examples/record_add_command'

RSpec.describe Underware::Commands::Layout::Add do
  let(:record_path) do
    Underware::FilePath.layout(type.pluralize, saved_record_name)
  end

  it_behaves_like 'record add command'

  it 'errors if the type does not exist' do
    expect do
      Underware::Utils.run_command(described_class,
                                   'missing-type',
                                   'record-name',
                                   stderr: StringIO.new)
    end.to raise_error(Underware::InvalidInput)
  end
end
