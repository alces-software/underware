
# frozen_string_literal: true

require 'filesystem'
require 'spec_utils'
require 'shared_examples/render_domain_templates'

RSpec.describe Metalware::CommandHelpers::ConfigureCommand do
  TEST_COMMAND_NAME = :testcommand

  # Subclass of `ConfigureCommand` for use in tests, to test it independently
  # of any individual subclass.
  class TestCommand < Metalware::CommandHelpers::ConfigureCommand
    protected

    def setup(args, options); end

    # Overridden to be three element array with third a valid `configure.yaml`
    # questions section; `BaseCommand` expects command classes to be namespaced
    # by two modules, and `ConfigureCommand` determines questions section,
    # which must be valid, from the class name.
    def class_name_parts
      [:some, :namespace, :domain]
    end

    def answers_file
      '/var/lib/metalware/answers/some_file.yaml'
    end
  end

  include_examples :render_domain_templates, TestCommand
end
