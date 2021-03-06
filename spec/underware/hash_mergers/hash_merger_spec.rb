
# frozen_string_literal: true

# =============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Architect.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Architect is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Architect. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Architect, please visit:
# https://github.com/openflighthpc/flight-architect
# ==============================================================================

require 'underware/hash_mergers'
require 'underware/data'
require 'underware/constants'
require 'underware/spec/alces_utils'

RSpec.describe Underware::HashMergers::HashMerger do
  include Underware::AlcesUtils

  Underware::AlcesUtils.mock self, :each do
    validation_off
  end

  before :each do
    fp = Underware::FilePath

    base_configure = YAML.dump(
      questions: [],
      domain: [],
      group: [],
      node: []
    )
    dst = Underware::FilePath.configure
    FileUtils.mkdir_p(File.dirname(dst))
    File.write(dst, base_configure)

    dump_data = lambda do |data, config_path, answers_path|
      [config_path, answers_path].each do |path|
        Underware::Data.dump(path, data)
      end
    end

    # We set up various simple, identical data files for both configs and
    # answers at different levels, so we can test that merging works
    # correctly for both config and answer HashMergers.
    dump_data.call(domain_data, fp.domain_config, fp.domain_answers)
    dump_data.call(group1_data, fp.group_config('group1'), fp.group_answers('group1'))
    dump_data.call(group2_data, fp.group_config('group2'), fp.group_answers('group2'))
    dump_data.call(node3_data, fp.node_config('node3'), fp.node_answers('node3'))

    # Platforms only have configs, and no answers, so we only dump a single
    # data file for the test platform config.
    Underware::Data.dump(fp.platform_config('test_platform'), test_platform_config)
  end

  let(:domain_data) do
    {
      value0: 'domain',
      value1: 'domain',
      value2: 'domain',
      value3: 'domain',
      value4: 'domain',
    }
  end

  let(:group1_data) do
    {
      value2: 'group1',
      value3: 'group1',
      value4: 'group1',
    }
  end

  let(:group2_data) do
    {
      value1: 'group2',
      value2: 'group2',
      value3: 'group2',
      value4: 'group2',
    }
  end

  let(:node3_data) do
    {
      value3: 'node3',
      value4: 'node3',
    }
  end

  let(:test_platform_config) do
    {
      value4: 'test_platform'
    }
  end

  def merged_namespace
    config = Underware::HashMergers::Config
      .new(eager_render: false)
      .merge(**hash_input, &:itself)
    answer = Underware::HashMergers::Answer
      .new(alces, eager_render: false)
      .merge(**hash_input, &:itself)
    OpenStruct.new(config: config, answer: answer)
  end

  RSpec.shared_examples 'it handles merging config, with and without platform specified' do
    it 'correctly merges config without platform specified' do
      expect(merged_namespace.config.to_h).to eq(expected_merged_config)
    end

    context 'when platform included in hash' do
      let(:hash_input) do
        super().merge(platform: 'test_platform')
      end

      it 'correctly merges config, with platform config taking precedence' do
        expect(
          merged_namespace.config.to_h
        ).to eq(
          expected_merged_config.merge(value4: 'test_platform')
        )
      end
    end
  end

  context 'with domain scope' do
    let(:hash_input) { {} }

    let(:expected_merged_config) { domain_data }

    it_behaves_like 'it handles merging config, with and without platform specified'
  end

  context 'with single group' do
    let(:hash_input) do
      {groups: ['group2']}
    end

    let(:expected_merged_config) do
      {
        value0: 'domain',
        value1: 'group2',
        value2: 'group2',
        value3: 'group2',
        value4: 'group2',
      }
    end

    it_behaves_like 'it handles merging config, with and without platform specified'
  end

  context 'with multiple groups' do
    let(:hash_input) do
      {groups: ['group1', 'group2']}
    end

    let(:expected_merged_config) do
      {
        value0: 'domain',
        value1: 'group2', # Not set for group1 so group2's value used.
        value2: 'group1',
        value3: 'group1',
        value4: 'group1',
      }
    end

    it_behaves_like 'it handles merging config, with and without platform specified'
  end

  context 'with multiple groups and a node' do
    let(:hash_input) do
      {
        groups: ['group1', 'group2'],
        node: 'node3'
      }
    end

    let(:expected_merged_config) do
      {
        value0: 'domain',
        value1: 'group2',
        value2: 'group1',
        value3: 'node3',
        value4: 'node3',
      }
    end

    let(:expected_merged_answers) { expected_merged_config }

    it_behaves_like 'it handles merging config, with and without platform specified'

    it 'correctly merges answers' do
      expect(merged_namespace.answer.to_h).to eq(expected_merged_answers)
    end
  end
end
