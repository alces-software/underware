
# frozen_string_literal: true


RSpec.describe Underware::CommandHelpers::ConfigureCommand do
  TEST_COMMAND_NAME = :testcommand

  # Subclass of `ConfigureCommand` for use in tests, to test it independently
  # of any individual subclass.
  class TestCommand < Underware::CommandHelpers::ConfigureCommand
    private

    # Overridden to be three element array with third a valid `configure.yaml`
    # questions section; `BaseCommand` expects command classes to be namespaced
    # by two modules.
    def class_name_parts
      [:some, :namespace, :test]
    end

    def answer_file
      Underware::FilePath.domain_answers
    end

    def configurator
      Underware::Configurator.new(alces, questions_section: :domain)
    end
  end

  describe 'option handling' do
    it 'passes answers through to configurator as hash' do
      Underware::DataCopy.init_cluster(Underware::CommandConfig.load.current_cluster)
      answers = { question_1: 'answer_1' }
      expect_any_instance_of(Underware::Configurator)
        .to receive(:configure).with(answers)

      Underware::Utils.run_command(TestCommand, answers: answers.to_json)
    end
  end
end
