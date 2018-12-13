
require 'shared_examples/render_command'
require 'underware/commands/render/node'

RSpec.describe Underware::Commands::Render::Node do
  include_context 'render command'

  before :each do
    allow(Underware::NodeattrInterface)
      .to receive(:all_nodes)
      .and_return([test_node_name])
  end

  let :test_node_name { 'testnode01' }

  let :command_args do
    [test_node_name, template.path]
  end

  it 'renders template against the given node and outputs result' do
    output = run_command(*command_args)

    expect(output).to include "Rendered with scope: Underware::Namespaces::Node\n"
    expect(output).to include "Scope name: #{test_node_name}\n"
  end

  it 'gives error if node cannot be found' do
    expect do
      run_command('unknown_node01', template.path)
    end.to raise_error(
      Underware::InvalidInput, "Could not find node: unknown_node01"
    )
  end
end