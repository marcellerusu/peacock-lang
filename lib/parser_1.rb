require "parser_utils"
require "ast"

module FirstPass
  class BoolParser < Parser
    def self.can_parse?(_self)
      _self.current_token&.type == :bool_lit
    end

    def parse!
      bool_t = consume! :bool_lit
      AST::Bool.new(bool_t.value, bool_t.start_pos, bool_t.end_pos)
    end
  end

  class NullParser < Parser
    def self.can_parse?(_self)
      _self.current_token&.type == :null
    end

    def parse!
      null_t = consume! :null
      AST::Null.new(null_t.start_pos, null_t.end_pos)
    end
  end

  class EqAssignmentParser < Parser
    def self.can_parse?(lhs, _self)
      _self.peek_token&.type == :"="
    end

    def parse!(lhs)
      consume! :"="
      expr_n = consume_parser! ExprParser
      AST::EqAssign.new(lhs, expr_n, id_t.start_pos, expr_n.end_pos)
    end
  end

  class ColonEqAssignmentParser < Parser
    def self.can_parse?(lhs, _self)
      _self.peek_token&.type == :assign
    end

    def parse!(lhs)
      consume! :assign
      expr_n = consume_parser! ExprParser
      AST::ColonEqAssign.new(lhs, expr_n, id_t.start_pos, expr_n.end_pos)
    end
  end

  class OrEqParser < Parser
    def self.can_parse?(_self, lhs)
      _self.current_token&.type == :"||="
    end

    def parse!(lhs_n)
      consume! :"||="
      expr_n = consume_parser! ExprParser
      AST::OrEq.new(lhs_n, expr_n, lhs_n.start_pos, expr_n.end_pos)
    end
  end

  class PlusEqParser < Parser
    def self.can_parse?(_self, lhs)
      _self.current_token&.type == :"+="
    end

    def parse!(lhs_n)
      consume! :"+="
      expr_n = consume_parser! ExprParser
      AST::PlusEq.new(lhs_n, expr_n, lhs_n.start_pos, expr_n.end_pos)
    end
  end

  class MinusEqParser < Parser
    def self.can_parse?(_self, lhs)
      _self.current_token&.type == :"-="
    end

    def parse!(lhs_n)
      consume! :"-="
      expr_n = consume_parser! ExprParser
      AST::PlusEq.new(lhs_n, expr_n, lhs_n.start_pos, expr_n.end_pos)
    end
  end

  class WhenParser < Parser
    def self.can_parse?(_self)
      _self.current_token&.type == :when
    end

    def parse!
      when_t = consume! :when
      expr_n = consume_parser! ExprParser
      body = consume_body! end_tokens: [:when, :else]
      AST::When.new(expr_n, body, when_t.start_pos, body.last&.end_pos || expr_n.end_pos)
    end
  end

  class FunctionParser < Parser
    def self.can_parse?(_self)
      _self.current_token&.type == :function
    end

    PARSERS = []

    def parse!
      consume! :function
      name_t = consume! :identifier
      }consume_first_valid_parser! PARSERS
    end
  end
end
