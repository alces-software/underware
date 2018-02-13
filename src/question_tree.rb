
require 'rubytree'

module Metalware
  class QuestionTree < Tree::TreeNode
    BASE_TRAVERSALS = [
      :each,
      :breadth_each,
      :postordered_each,
      :preordered_each
    ]

    def questions_length
      num = 0
      each { |_q| num += 1 }
      num
    end

    def question?
      !!identifier
    end

    def identifiers
      map do |question|
        question.identifier
      end
    end

    def identifier
      content[:identifier]
    end
  end
end

