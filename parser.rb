require 'parslet'

require_relative 'error_handler'

# This class contains all the rules from the Aspire language. It is used to
# parse a string into a specialized hash and return meaningful errors in case
# that fails.
class Parser < Parslet::Parser
  include ErrorHandler

  root(:functions)

  rule(:functions, label: 'functions') do
    repeat_separated function, space, spaced: false
  end

  rule(:function, label: 'function') do
    (signature >> space >> block).as(:function)
  end

  rule(:signature, label: 'function signature') do
    identifier.as(:name) >> space >> left_paren >> identifiers.as(:args) >>
      right_paren
  end

  rule(:identifiers, label: 'identifiers') do
    repeat_separated identifier, comma
  end

  rule(:for_statement, label: 'for statement') do
    (str('for') >> space >> left_paren >> space >> identifier.as(:element) >>
      space >> str(':') >> space >> (identifier | array).as(:array) >> space >>
      right_paren >> space >> block).as(:for_statement)
  end

  rule(:if_statement, label: 'if statement') do
    (str('if') >> space >> left_paren >> value.as(:condition) >> space >>
      right_paren >> space >> block).as(:if_block)
  end

  rule(:if_else_statement, label: 'if-else statement') do
    (str('if') >> space >> left_paren >> value.as(:condition) >> space >>
      right_paren >> space >> block.as(:if_block) >> space >> str('else') >>
      space >> block.as(:else_block)).as(:if_else_statement)
  end

  rule(:block, label: 'function block') do
    (left_brace >> space >> statements >> space >> right_brace).as(:block)
  end

  rule(:statements, label: 'statements') do
    repeat_separated statement, (
      (unbreakable_space >> new_line >> space) | (space >> semicolon >> space)
    ), spaced: false
  end

  rule(:statement, label: 'statement') do
    for_statement | if_else_statement | if_statement | value
  end

  rule(:value, label: 'value') do
    expression | non_expression
  end

  rule(:non_expression, label: 'non-expression') do
    block | assignment | array | matrix | vector | color | float | integer |
      boolean | identifier | enclosed
  end

  rule(:expression, label: 'expression') { unary }

  rule(:unary, label: 'unary expression') do
    ((sign | negation_op).as(:o) >> (float | integer).absent? >>
      infix.as(:v)).as(:expression) | infix
  end

  rule(:infix, label: 'infix expression') do
    (non_expression >> space >> op).present? >>
    infix_expression(
      space >> non_expression >> space,
      [or_op, 11],
      [xor_op, 10],
      [and_op, 9],
      [bitwise_or_op, 8],
      [bitwise_xor_op, 7],
      [bitwise_and_op, 6],
      [equality_op, 5],
      [relational_op, 4],
      [shift_op, 3],
      [additive_op, 2],
      [multiplicative_op, 1]
    ).as(:expression) | non_expression
  end

  rule(:assignment, label: 'assignment') do
    (identifier >> space >> str('=') >> space >> value).as(:assignment)
  end

  rule(:enclosed, label: 'parenthesis-enclosed value') do
    left_paren >> space >> value >> space >> right_paren
  end

  rule(:values, label: 'comma separated values') do
    repeat_separated value, comma
  end

  rule(:values_2, label: 'comma separated values (min. 2)') do
    repeat_separated value, comma, min: 2
  end

  rule(:array, label: 'array') do
    (left_bracket >> values >> right_bracket).as(:array)
  end

  rule(:matrix, label: 'matrix') do
    (left_paren >> vectors_2 >> right_paren).as(:matrix)
  end

  rule(:vectors_2, label: 'comma separated vectors (min. 2)') do
    repeat_separated vector, comma, min: 2
  end

  rule(:vector, label: 'vector') do
    (left_paren >> space >> values_2 >> right_paren).as(:vector)
  end

  rule(:identifier, label: 'identifier') do
    (alpha_underscore >> alphanum_underscore.repeat).as(:identifier)
  end

  rule(:color, label: 'color') do
    (str('#') >> (color_24bit >> alpha.maybe | color_12bit)).as(:color)
  end

  rule(:color_24bit, label: '24-bit color') { hex_digit.repeat(6, 6) }
  rule(:color_12bit, label: '12-bit color') { hex_digit.repeat(3, 3) }
  rule(:alpha, label: 'alpha') { hex_digit.repeat(2, 2) }

  rule(:float, label: 'float') do
    (sign.maybe >> fraction >> exponent.maybe).as(:float)
  end

  rule(:fraction, label: 'fraction') do
    number >> decimal_point >> digits.maybe |
      number.maybe >> decimal_point >> digits
  end

  rule(:exponent, label: 'exponent') do
    match['Ee'] >> sign.maybe >> (digit_19_digits | digit)
  end

  rule(:integer, label: 'integer') do
    (sign.maybe >> number).as(:integer)
  end

  rule(:number, label: 'number') { digit_19_digits | digit }

  rule(:digits, label: 'digits') { digit.repeat(1) }
  rule(:digit_19_digits, label: 'non-null digit followed by digits') do
    digit_19 >> digits
  end

  rule(:boolean, label: 'boolean') { (str('true') | str('false')).as(:boolean) }

  rule(:op, label: 'infix operator') do
    or_op | xor_op | and_op | bitwise_or_op | bitwise_xor_op | bitwise_and_op |
      equality_op | shift_op | relational_op | additive_op | multiplicative_op
  end
  rule(:or_op, label: 'or operator') { str('||') }
  rule(:xor_op, label: 'xor operator') { str('^^') }
  rule(:and_op, label: 'and operator') { str('&&') }
  rule(:bitwise_or_op, label: 'bitwise or operator') { str('|') }
  rule(:bitwise_xor_op, label: 'bitwise xor operator') { str('^') }
  rule(:bitwise_and_op, label: 'bitwise and operator') { str('&') }
  rule(:equality_op, label: 'equality operator') { str('==') | str('!=') }
  rule(:relational_op, label: 'relational operator') do
    str('<=') | str('>=') | (str('<') | str('>')) >> match['<>'].absent?
  end
  rule(:shift_op, label: 'shift operator') { str('<<') | str('>>') }
  rule(:multiplicative_op, label: 'multiplicative operator') { match['*/%'] }
  rule(:additive_op, label: 'additive operator') { match['+-'] }
  rule(:negation_op, label: 'negation operator') { str('!') }

  rule(:space, label: 'optional space') { match['\s'].repeat }
  rule(:unbreakable_space, label: 'optional unbreakable space') do
    str(' ').repeat
  end
  rule(:new_line, label: 'new live') { str("\n") }

  rule(:comma, label: 'comma') { str(',') }
  rule(:semicolon, label: 'semicolon') { str(';') }

  rule(:left_brace, label: 'left brace') { str('{') }
  rule(:right_brace, label: 'right brace') { str('}') }

  rule(:left_bracket, label: 'left bracket') { str('[') }
  rule(:right_bracket, label: 'right bracket') { str(']') }

  rule(:left_paren, label: 'left parenthesis') { str('(') }
  rule(:right_paren, label: 'right parenthesis') { str(')') }

  rule(:alpha_underscore, label: 'alpha with underscore') { match['a-zA-Z_'] }
  rule(:alphanum_underscore, label: 'alphanumeric with underscore') do
    match['a-zA-Z0-9_']
  end

  rule(:hex_digit, label: 'hexadecimal digit') { match['0-9a-fA-F'] }

  rule(:digit, label: 'digit') { match['\d'] }
  rule(:digit_19, label: 'non-null digit') { match['1-9'] }

  rule(:decimal_point, label: 'decimal point') { str('.') }

  rule(:sign, label: 'sign') { match['+-'] }

  def repeat_separated(value, separator, spaced: true, min: 0)
    separator = space >> separator >> space if spaced

    rule = (value >> (separator >> value.present?).maybe).repeat min

    spaced ? space >> rule >> space : rule
  end
end
