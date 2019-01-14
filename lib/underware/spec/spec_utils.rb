# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
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
require 'underware/constants'
require 'underware/dependency'

module Underware
  module SpecUtils
    # Mocks.
    def use_mock_determine_hostip_script
      stub_const(
        'Underware::Constants::UNDERWARE_INSTALL_PATH',
        FIXTURES_PATH
      )
    end

    # Other shared utils.

    def enable_output_to_stderr
      $rspec_suppress_output_to_stderr = false
    end
  end
end
