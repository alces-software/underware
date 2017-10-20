
# frozen_string_literal: true

require 'namespaces/alces'
require 'spec_utils'

RSpec.describe Metalware::Namespaces::Node do
  context 'with mocked group' do
    include AlcesUtils

    AlcesUtils.mock self, :each do
      mock_group('test_group')
    end

    include_examples Metalware::Namespaces::HashMergerNamespace, :group
  end
end
