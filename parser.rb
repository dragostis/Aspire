require 'parslet'

require_relative 'error_handler'

# This class contains all the rules from the Aspire language. It it used to
# parse a string into a specialized hash and returning meaningful errors in case
# that fails.
class Parser < Parslet::Parser
  include ErrorHandler

  root(:value)

  rule(:value, label: 'value') do
    color | float | integer | boolean | identifier
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
    digits >> decimal_point >> digits.maybe |
      digits.maybe >> decimal_point >> digits
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
