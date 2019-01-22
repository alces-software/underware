# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd.
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

RSpec.describe Underware::AlcesUtils do
  include described_class

  let(:file_path) { Underware::FilePath }

  describe '#new' do
    it 'returns the mocked alces' do
      new_alces = Underware::Namespaces::Alces.new
      expect(alces.equal?(new_alces)).to eq(true)
    end
  end

  describe '#define_method_testing' do
    it 'runs the method block' do
      Underware::AlcesUtils::Mock.new(self).define_method_testing do
        'value'
      end
      expect(alces.testing).to eq('value')
    end
  end

  context 'with the AlceUtils.mock method' do
    before do
      Underware::AlcesUtils::Mock.new(self)
                      .define_method_testing {} # Intentionally blank
    end

    context 'with a block before each test' do
      described_class.mock self, :each do
        allow(alces).to receive(:testing).and_return(100)
      end

      it 'gets the value' do
        expect(alces.testing).to eq(100)
      end
    end

    context 'with the config mocked' do
      let(:domain_config) do
        { key: 'domain' }
      end

      described_class.mock self, :each do
        config(alces.domain, domain_config)
      end

      it 'mocks the config' do
        expect(alces.domain.config.key).to eq('domain')
      end
    end

    context 'with a mocked config' do
      described_class.mock self, :each do
        validation_off
      end

      it 'turns the validation off' do
        expect(Underware::Constants::SKIP_VALIDATION).to be true
      end
    end

    context 'with blank config' do
      described_class.mock self, :each do
        with_blank_config_and_answer(alces.domain)
      end

      it 'has a blank config' do
        expect(alces.domain.config.to_h).to be_empty
      end

      it 'has a blank answer' do
        expect(alces.domain.answer.to_h).to be_empty
      end

      it 'can still overide the config' do
        described_class.mock self do
          config(alces.domain, key: 'domain')
        end

        expect(alces.domain.config.key).to eq('domain')
      end
    end

    describe '#mock_group' do
      let(:group) { 'some random group' }
      let(:group2) { 'some other group' }

      described_class.mock self, :each do
        mock_group(group)
      end

      it 'creates the group' do
        expect(alces.groups.send(group).name).to eq(group)
      end

      it 'can add another group' do
        alces.groups # Initializes the old groups first
        described_class.mock(self) { mock_group(group2) }
        expect(alces.groups.send(group2).name).to eq(group2)
      end

      # The mocking would otherwise alter the actual file
      it 'errors if FakeFS is off' do
        FakeFS.deactivate!
        expect do
          described_class.mock(self) { mock_group(group2) }
        end.to raise_error(RuntimeError)
      end

      it 'returns the new mocked group' do
        name = 'my-super-new-group'
        described_class.mock self do
          expect(mock_group(name).name).to eq(name)
        end
      end
    end

    describe '#mock_node' do
      let(:name) { 'some_random_test_node3456734' }
      let(:second_node_name) { 'some_random_new_node4362346' }
      let(:second_node_genders) { ['_some_group_1', '_some_group_2'] }
      let!(:node) do
        described_class.mock(self) { mock_node(name) }
      end
      let(:second_node) do
        described_class.mock(self) do
          mock_node(second_node_name, *second_node_genders)
        end
      end

      it 'creates the mock node' do
        expect(node.name).to eq(name)
      end

      it 'appears in the nodes list' do
        expect(alces.nodes.length).to eq(2)
        expect(alces.nodes.find_by_name(name).name).to eq(name)
      end

      it 'adds the node to default test group' do
        expect(node.genders).to eq([described_class.default_group])
      end

      it 'uses the genders input' do
        expect(second_node.genders).to eq(second_node_genders)
      end
    end

    describe '#reset_alces' do
      let!(:old_alces) { alces }

      before do
        described_class.mock(self) do
          config(alces.domain, key: 'I should be deleted in the reset')
        end
        reset_alces
      end

      it 'resets alces to a new instance' do
        expect(alces).not_to eq(old_alces)
      end

      it 'removes the old config mocking' do
        expect(alces.domain.config.keys).to be_nil
      end

      it 'sets the Alces.new method to return the new alces object' do
        new_alces = Underware::Namespaces::Alces.new
        expect(new_alces).to eq(alces)
      end

      it 'returns the new version of alces' do
        return_from_reset_alces = reset_alces
        expect(return_from_reset_alces).to eq(alces)
      end
    end
  end

  describe '#redirect_std' do
    let(:test_str) { 'Testing' }

    def redirect_stdout
      test_stdout = StringIO.new
      old_stdout = $stdout
      begin
        $stdout = test_stdout
        yield
      ensure
        $stdout = old_stdout
      end
      test_stdout.rewind
      test_stdout.read
    end

    it 'can redirect stdout' do
      io = described_class.redirect_std(:stdout) do
        $stdout.puts test_str
      end
      expect(io[:stdout].read.chomp).to eq(test_str)
    end

    it 'can redirect stderr' do
      io = described_class.redirect_std(:stderr) do
        warn test_str
      end
      expect(io[:stderr].read.chomp).to eq(test_str)
    end

    it 'resets stdout' do
      stdout = redirect_stdout do
        described_class.redirect_std(:stdout) { puts 'Captured' }
        puts test_str
      end
      expect(stdout.chomp).to eq(test_str)
    end
  end
end
