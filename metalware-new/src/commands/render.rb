
require 'commands/basecommand'
require 'templater'

module Metalware
  module Commands
    class Render < BaseCommand
      def setup(args, options)
        @args = args
      end

      def run
        template_path, maybe_node = @args

        template_parameters = {
          nodename: maybe_node,
        }.reject { |param, value| value.nil? }
        templater = Templater::Combiner.new(template_parameters)

        rendered = templater.file(template_path)
        puts rendered
      end
    end
  end
end
