require 'parslet'

require_relative 'error_handler'

# This class contains all the rules from the Aspire language. It it used to
# parse a string into a specialized hash and returning meaningful errors in case
# that fails.
class Parser < Parslet::Parser
  include ErrorHandler

  root(:value)

  rule(:value, label: 'value') do
    array | matrix | vector | color | float | integer | boolean | identifier
  end

  rule(:values, label: 'comma separated values') do
    (value >> space_breaks >>
      (comma >> space_breaks >> right_bracket.absent? | right_bracket.present?))
      .repeat
  end

  rule(:values_2, label: 'comma separated values (min. 2)') do
    (value >> space_breaks >>
      (comma >> space_breaks >> right_paren.absent? | right_paren.present?))
      .repeat(2)
  end

  rule(:array, label: 'array') do
    (left_bracket >> space_breaks >> values >> right_bracket).as(:array)
  end

  rule(:matrix, label: 'matrix') do
    (left_paren >> space_breaks >> vectors_2 >> right_paren).as(:matrix)
  end

  rule(:vectors_2, label: 'comma separated vectors (min. 2)') do
    (vector >> space_breaks >>
      (comma >> space_breaks >> right_paren.absent? | right_paren.present?))
      .repeat(2)
  end

  rule(:vector, label: 'vector') do
    (left_paren >> space_breaks >> values_2 >> right_paren).as(:vector)
  end

  rule(:identifier, label: 'identifier') do
    (alpha_underscore >> alphanum_underscore.repeat).as(:identifier)
  end

  rule(:color, label: 'color') do
    (str('#') >> (color_12bit | color_24bit >> alpha.maybe)).as(:color)
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
    match['Ee'] >> sign >> (digit_19_digits | digit)
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

  rule(:space, label: 'optional space') { match['\s'].repeat }
  rule(:space_breaks, label: 'optional space with breaks') do
    match['\s\n'].repeat
  end

  rule(:comma, label: 'comma') { str(',') }

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
end
