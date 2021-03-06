
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

require 'underware/templating/nil_detection_wrapper'
require 'recursive_open_struct'
require 'underware/underware_log'
require 'underware/spec/alces_utils'

RSpec.describe Underware::Templating::NilDetectionWrapper do
  Underware::AlcesUtils.start self

  def build_wrapper_object(obj)
    Underware::Templating::NilDetectionWrapper.wrap(obj).receiver
  end

  def expect_warning(msg)
    expect(underware_log).to receive(:warn).once.with(/.*#{msg}\Z/)
  end

  let(:underware_log) { Underware::UnderwareLog.underware_log }

  it 'the wrap command returns a binding' do
    expect(described_class.wrap(nil)).to \
      be_a(Binding)
  end

  context 'with a falsey result' do
    let(:false_obj) do
      build_wrapper_object(OpenStruct.new(nil_key: nil, false_key: false))
    end

    def expect_falsey(value)
      expect(value ? true : false).to be(false)
    end

    it 'preserves the falsey-ness of nil' do
      expect_falsey(false_obj.nil_key)
    end

    it "preserves the falsey-ness of 'false'" do
      expect_falsey(false_obj.false_key)
    end
  end

  context 'with a wrapped integer' do
    let(:object) { 100 }
    let(:wrapped_object) { build_wrapper_object(object) }

    it 'the wrapped object is equal to the object' do
      expect(wrapped_object).to eq(object)
    end

    context 'when multipled by 0' do
      let(:zero_object) { wrapped_object * 0 }

      it 'equals the correct value' do
        expect(zero_object).to eq(0)
      end

      it 'can have methods called on it' do
        expect(zero_object.zero?).to eq(true)
      end
    end
  end

  context 'with a recursive_open_struct object' do
    let(:object) do
      RecursiveOpenStruct.new(
        nil: nil,
        true_key: true,
        false_key: false,
        key1: {
          key2: {
            key3: {
              key4: nil,
            },
          },
        }
      )
    end

    let(:wrapped_object) { build_wrapper_object(object) }

    it 'issues for a simple nil return value' do
      expect_warning('nil')
      expect(wrapped_object.nil).to be_a(NilClass)
    end

    it 'issues a warning for a nested nil' do
      expect_warning('key1.key2.key3.key4')
      wrapped_object.key1.key2.key3.key4
    end

    it 'false is still a FalseClass' do
      expect(wrapped_object.false_key).to be_a(FalseClass)
      expect(wrapped_object.false_key).to be_falsey
    end

    it 'true is still a TrueClass' do
      expect(wrapped_object.true_key).to be_a(TrueClass)
      expect(wrapped_object.true_key).to be_truthy
    end
  end

  context 'with multiple input arguments' do
    let(:wrapped_object) do
      d = double('object', test: nil, :[] => nil)
      build_wrapper_object(d)
    end

    it 'displays if a block is passed in' do
      expect_warning('test\(&block\)')
      wrapped_object.test { puts 'I am a blocky block' }
    end

    it 'displays the additional args' do
      expect_warning('test\(arg1, arg2\)')
      wrapped_object.test('arg1', 'arg2')
    end

    it 'converts [] method call (with symbol)' do
      expect_warning('\[:key\]')
      wrapped_object[:key]
    end

    it 'converts [] method calls (with string)' do
      expect_warning('\[\'key\'\]')
      wrapped_object['key']
    end

    it 'gets the order correct' do
      expect_warning('\[:key\]\(arg2, arg3, &block\)')
      wrapped_object.[](:key, 'arg2', 'arg3') { puts 'I am a block' }
    end
  end
end
