
# frozen_string_literal: true

require 'terminal-table'

require 'repo'

module Metalware
  class AnswersTableCreator
    def initialize(config)
      @config = config
    end

    def domain_table
      answers_table
    end

    def primary_group_table(group_name)
      answers_table(group_name: group_name)
    end

    def node_table(node_name)
      group_name = Node.new(config, node_name).primary_group
      answers_table(group_name: group_name, node_name: node_name)
    end

    private

    attr_reader :config

    def answers_table(group_name: nil, node_name: nil)
      Terminal::Table.new(
        headings: headings(group_name: group_name, node_name: node_name),
        rows: rows(group_name: group_name, node_name: node_name)
      )
    end

    def headings(group_name:, node_name:)
      [
        'Question',
        'Domain',
        group_name ? "Group: #{group_name}" : nil,
        node_name ?  "Node: #{node_name}" : nil,
      ].reject(&:nil?)
    end

    def rows(group_name:, node_name:)
      configure_questions.map do |question|
        [
          question,
          domain_answer(question: question),
          group_answer(question: question, group_name: group_name),
          node_answer(question: question, node_name: node_name),
        ].reject(&:nil?)
      end
    end

    def configure_questions
      repo.configure_questions
    end

    def repo
      @repo ||= Metalware::Repo.new(config)
    end

    def domain_answer(question:)
      format_answer(question: question, file: domain_answers_file)
    end

    def group_answer(question:, group_name:)
      if group_name
        format_answer(
          question: question,
          file: primary_group_answers_file(group_name)
        )
      end
    end

    def node_answer(question:, node_name:)
      if node_name
        format_answer(
          question: question,
          file: node_answers_file(node_name)
        )
      end
    end

    def format_answer(question:, file:)
      # `inspect` the answer to get it with an indication of its type, so e.g.
      # strings are wrapped in quotes, and can distinguish from integers etc.
      Data.load(file)[question].inspect
    end

    # XXX Duplicated from `configure domain`.
    def domain_answers_file
      File.join(config.answer_files_path, 'domain.yaml')
    end

    # XXX Duplicated from `configure group`.
    def primary_group_answers_file(group_name)
      File.join(config.answer_files_path, 'groups', "#{group_name}.yaml")
    end

    # XXX Duplicated from `configure node`.
    def node_answers_file(node_name)
      File.join(config.answer_files_path, 'nodes', "#{node_name}.yaml")
    end
  end
end
