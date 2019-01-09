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

require 'underware/cluster_attr'

RSpec.describe Underware::ClusterAttr do
  shared_context 'with a ClusterAttr instance' do
    let(:cluster_name) { 'my-test-cluster' }
    subject { described_class.new(cluster_name) }
  end

  describe '::expand' do
    it 'can expand multiple nodes' do
      node_str = 'node[01-10]'
      nodes = (1...10).map { |i| "node0#{i}" }
                      .push('node10')
      expect(described_class.expand(node_str)).to contain_exactly(*nodes)
    end
  end

  context 'without any additional groups' do
    include_context 'with a ClusterAttr instance'

    it 'contains the orphan group' do
      expect(subject.raw_groups).to include('orphan')
    end
  end

  context 'when adding a single group' do
    include_context 'with a ClusterAttr instance'

    let(:first_group) { 'my-first-group' }

    before { subject.add_group(first_group) }

    it 'adds the group' do
      expect(subject.raw_groups).to include(first_group)
    end
  end
end
