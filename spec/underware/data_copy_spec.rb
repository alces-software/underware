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

require 'underware/data_copy'
require 'pathname'

RSpec.describe Underware::DataCopy do
  def touch_file(path)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
  end

  def expect_path(path)
    expect(Pathname.new(path))
  end

  shared_context 'with base files' do
    let(:join_base_files) { ['base-file1', 'base-file2'] }
    let(:base_path) { Underware::DataPath.new }
    before do
      join_base_files.each { |p| touch_file(base_path.join(p)) }
    end
  end

  shared_context 'with existing cluster1 files' do
    let(:cluster1_path) { Underware::DataPath.cluster('cluster1') }
    let(:join_cluster1_files) do
      [
        'file1',
        'directory/file2',
        'directory/sub-directory/file3'
      ]
    end
    let(:cluster1_files) do
      join_cluster1_files.map { |p| cluster1_path.join(p) }
    end

    before { cluster1_files.each { |p| touch_file(p) } }
  end

  shared_context 'with an existing overlay' do
    let(:overlay) { 'my-overlay' }
    let(:overlay_path) { Underware::DataPath.overlay(overlay) }
    let(:join_overlay_files) { ['file1', 'directory/file2'] }

    before do
      join_overlay_files.each do |rel_path|
        touch_file(overlay_path.join(rel_path))
      end
    end
  end

  shared_context 'with a non-existant new cluster' do
    let(:new_cluster) { 'new-cluster' }
    let(:new_cluster_path) { Underware::DataPath.new(cluster: new_cluster) }
  end

  shared_examples 'copy to new cluster' do
    it 'copies the files to the new cluster' do
      expect_join_copied_files.each do |rel_path|
        expect_path(new_cluster_path.join(rel_path)).to be_exist
      end
    end
  end

  context 'when copying to a non existant cluster' do
    include_context 'with existing cluster1 files'
    include_context 'with a non-existant new cluster'

    let(:new_paths) do
      base = Pathname.new(cluster1_path.base)
      cluster1_files.map { |p| Pathname.new(p).join_path_from(base).to_s }
                    .map { |p| File.expand_path(p, new_cluster_path.base) }
    end
    subject do
      described_class.new(cluster1_path, new_cluster_path)
    end

    describe '#all' do
      let(:expect_join_copied_files) { join_cluster1_files }
      before { subject.all }

      include_examples 'copy to new cluster'
    end
  end

  describe '::overlay_to_cluster' do
    shared_examples 'a overlay cluster generator' do
      include_context 'with a non-existant new cluster'
      subject do
        described_class.overlay_to_cluster(subject_overlay, new_cluster)
      end

      describe '#all' do
        before { subject.all }
        include_examples 'copy to new cluster'
      end
    end

    shared_examples 'a protected copy' do
      # The `nil` cluster also corresponds to the base overlay. There should
      # be no way to copy to the base section through `overlay_to_cluster`
      # Similarly, it shouldn't be able to write to the empty string cluster
      ['', nil, false].each do |dst|
        it "errors when copying to the #{dst.inspect} cluster" do
          expect do
            described_class.overlay_to_cluster(subject_overlay, dst)
          end.to raise_error(Underware::InternalError)
        end
      end
    end

    context 'when the from the nil (aka base) overlay' do
      include_context 'with base files'
      let(:subject_overlay) { nil }
      let(:expect_join_copied_files) { join_base_files }

      it_behaves_like 'a overlay cluster generator'
      it_behaves_like 'a protected copy'
    end

    context 'when copying from a overlay' do
      include_context 'with an existing overlay'
      let(:subject_overlay) { overlay }
      let(:expect_join_copied_files) { join_overlay_files }

      it_behaves_like 'a overlay cluster generator'
      it_behaves_like 'a protected copy'
    end
  end

  describe '::init_cluster' do
    shared_examples 'a standard init' do
      include_context 'with base files'
      include_context 'with a non-existant new cluster'
      let(:expect_join_copied_files) { join_base_files }

      before do
        described_class.init_cluster(new_cluster)
      end

      include_examples 'copy to new cluster'
    end

    context 'when copying to a new cluster' do
      it_behaves_like 'a standard init'
    end
  end
end
