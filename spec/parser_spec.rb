require 'parslet'
require 'parslet/rig/rspec'

require_relative '../parser'

describe Parser do
  let(:parser) { Parser.new }

  context 'functions' do
    it 'parses blocks' do
      expect(parser.block).to parse '{3;4;5}'
      expect(parser.block).to parse "{\n3\n4;5\n}"
    end

    it 'parses signatured' do
      expect(parser.signature).to parse 'f()'
      expect(parser.signature).to parse 'f(a)'
      expect(parser.signature).to parse "f \n( \n a, a \n)"
      expect(parser.signature).to_not parse 'f(1)'
      expect(parser.signature).to_not parse 'f(a,)'
    end

    it 'parses functions' do
      expect(parser.function).to parse 'f(){}'
      expect(parser.function).to parse 'f(a){b}'
      expect(parser.function).to parse 'f(a,b){b;b}'
    end

    it 'parses multiple functions' do
      expect(parser.functions).to parse 'f(){}g(){}'
    end
  end

  context 'expressions' do
    it 'parses unary expressions' do
      expect(parser.value).to parse '-a'
      expect(parser.expression).to parse '-a'
      expect(parser.unary).to parse '-a'
      expect(parser.unary).to parse '+a'
      expect(parser.unary.parse '!a').to have_key :o
      expect(parser.unary.parse '-3').to_not have_key :o
    end

    it 'parses multiplications' do
      expect(parser.value).to parse '1*(1, 2)'
      expect(parser.expression).to parse 'a*b'
      expect(parser.unary).to parse 'a*b'
      expect(parser.infix).to parse 'a*b'
      expect(parser.infix).to parse 'a/b'
      expect(parser.infix).to parse 'a%b'
      expect(parser.infix).to parse 'a*b+c'
      expect(parser.infix.parse('a*b+c')[:o].to_s).to eql '*'
    end

    it 'parses additions' do
      expect(parser.value).to parse '1+(1, 2)'
      expect(parser.expression).to parse 'a+b'
      expect(parser.unary).to parse 'a+b'
      expect(parser.infix).to parse 'a+b'
      expect(parser.infix).to parse 'a-b'
      expect(parser.infix).to parse 'a+b>>c'
      expect(parser.infix.parse('a+b>>c')[:o].to_s).to eql '+'
    end

    it 'parses shifts' do
      expect(parser.value).to parse '1>>(1, 2)'
      expect(parser.expression).to parse 'a>>b'
      expect(parser.unary).to parse 'a>>b'
      expect(parser.infix).to parse 'a>>b'
      expect(parser.infix).to parse 'a<<b'
      expect(parser.infix).to parse 'a>>b>c'
      expect(parser.infix.parse('a>>b>c')[:o].to_s).to eql '>>'
    end

    it 'parses relations' do
      expect(parser.value).to parse '1<(1, 2)'
      expect(parser.expression).to parse 'a<b'
      expect(parser.unary).to parse 'a<b'
      expect(parser.infix).to parse 'a<b'
      expect(parser.infix).to parse 'a>b'
      expect(parser.infix).to parse 'a<=b'
      expect(parser.infix).to parse 'a>=b'
      expect(parser.infix).to parse 'a<b==c'
      expect(parser.infix.parse('a<b==c')[:o].to_s).to eql '<'
    end

    it 'parses equalities' do
      expect(parser.value).to parse '1==(1, 2)'
      expect(parser.expression).to parse 'a==b'
      expect(parser.unary).to parse 'a==b'
      expect(parser.infix).to parse 'a==b'
      expect(parser.infix).to parse 'a!=b'
      expect(parser.infix).to parse 'a==b&c'
      expect(parser.infix.parse('a==b&c')[:o].to_s).to eql '=='
    end

    it 'parses bitwise ands' do
      expect(parser.value).to parse '1&(1, 2)'
      expect(parser.expression).to parse 'a&b'
      expect(parser.unary).to parse 'a&b'
      expect(parser.infix).to parse 'a&b'
      expect(parser.infix).to parse 'a&b^c'
      expect(parser.infix.parse('a&b^c')[:o].to_s).to eql '&'
    end

    it 'parses bitwise xors' do
      expect(parser.value).to parse '1^(1, 2)'
      expect(parser.expression).to parse 'a^b'
      expect(parser.unary).to parse 'a^b'
      expect(parser.infix).to parse 'a^b'
      expect(parser.infix).to parse 'a^b|c'
      expect(parser.infix.parse('a^b|c')[:o].to_s).to eql '^'
    end

    it 'parses bitwise ors' do
      expect(parser.value).to parse '1|(1, 2)'
      expect(parser.expression).to parse 'a|b'
      expect(parser.unary).to parse 'a|b'
      expect(parser.infix).to parse 'a|b'
      expect(parser.infix).to parse 'a|b&&c'
      expect(parser.infix.parse('a|b&&c')[:o].to_s).to eql '|'
    end

    it 'parses ands' do
      expect(parser.value).to parse '1&&(1, 2)'
      expect(parser.expression).to parse 'a&&b'
      expect(parser.unary).to parse 'a&&b'
      expect(parser.infix).to parse 'a&&b'
      expect(parser.infix).to parse 'a&&b^^c'
      expect(parser.infix.parse('a&&b^^c')[:o].to_s).to eql '&&'
    end

    it 'parses xors' do
      expect(parser.value).to parse '1^^(1, 2)'
      expect(parser.expression).to parse 'a^^b'
      expect(parser.unary).to parse 'a^^b'
      expect(parser.infix).to parse 'a^^b'
      expect(parser.infix).to parse 'a^^b||c'
      expect(parser.infix.parse('a^^b||c')[:o].to_s).to eql '^^'
    end

    it 'parses ors' do
      expect(parser.value).to parse '1||(1, 2)'
      expect(parser.expression).to parse 'a||b'
      expect(parser.unary).to parse 'a||b'
      expect(parser.infix).to parse 'a||b'
    end

    it 'parses complex expressions' do
      expect(parser.expression).to parse(
        '(1, 2)*[]+2>>0.3e+10&((1,1),(1,1))^(1+2)|true&&a_3^^#000000||a')
    end
  end

  context 'non-expressions' do
    it 'parses assignments' do
      expect(parser.value).to parse 'a=0'
      expect(parser.assignment).to parse 'b=3'
      expect(parser.assignment).to parse "a \n = \n 3"
      expect(parser.assignment).to parse 'arc=(3,3)'
    end

    it 'parses parenthesis-enclosed values' do
      expect(parser.value).to parse '((false))'
      expect(parser.enclosed).to parse '(((2.3)))'
      expect(parser.enclosed).to_not parse '()(1)'
      expect(parser.enclosed).to_not parse ')1('
    end

    it 'parses booleans' do
      expect(parser.value).to parse 'true'
      expect(parser.boolean).to parse 'true'
      expect(parser.boolean).to parse 'false'
    end

    it 'parses integers' do
      expect(parser.value).to parse '123'
      expect(parser.integer).to parse '0'
      expect(parser.integer).to parse '10'
      expect(parser.integer).to parse '1234567890'
      expect(parser.integer).to parse '-10'
      expect(parser.integer).to parse '+10'
      expect(parser.integer).to_not parse '010'
    end

    it 'parses floats' do
      expect(parser.value).to parse '-0.0'
      expect(parser.float).to parse '0.'
      expect(parser.float).to parse '.0'
      expect(parser.float).to parse '1234567890.1234567890'
      expect(parser.float).to parse '-0.0'
      expect(parser.float).to parse '+0.0'
      expect(parser.float).to parse '0.0e10'
      expect(parser.float).to parse '0.0e+10'
      expect(parser.float).to parse '0.0e-10'
      expect(parser.float).to parse '-0.0E-10'
      expect(parser.float).to_not parse '00.0'
      expect(parser.float).to_not parse '0.0e-00'
    end

    it 'parses colors' do
      expect(parser.value).to parse '#ffffff'
      expect(parser.color).to parse '#000'
      expect(parser.color).to parse '#000000'
      expect(parser.color).to parse '#fff'
      expect(parser.color).to parse '#FFFFFF'
      expect(parser.color).to parse '#FFFFFF00'
      expect(parser.color).to_not parse '#ggg'
      expect(parser.color).to_not parse '#ffff'
      expect(parser.color).to_not parse '#fffff'
      expect(parser.color).to_not parse '#fffffff'
    end

    it 'parses vectors' do
      expect(parser.value).to parse '(0, 0)'
      expect(parser.vector).to parse '(1,2)'
      expect(parser.vector).to parse '(1, 2, 3, 4)'
      expect(parser.vector).to parse "(\n1 \n, \n2 , \n3\n)"
      expect(parser.vector).to parse '(true, false)'
      expect(parser.vector).to parse '(0.1, 1.0)'
      expect(parser.vector).to parse '(hey, ya)'
      expect(parser.vector).to_not parse '(1)'
      expect(parser.vector).to_not parse '(#fff)'
      expect(parser.vector).to_not parse '(1,)'
    end

    it 'parses matrices' do
      expect(parser.value).to parse '((0, 0), (0, 0))'
      expect(parser.matrix).to parse '((1, 2), (3, 4))'
      expect(parser.matrix).to parse '((1, 2), (3, 4), (1, 2), (3, 4))'
      expect(parser.matrix).to parse "((\n1 \n, \n2 , \n3\n)\n, \n(4, 5))"
      expect(parser.matrix).to_not parse '((1, 2))'
      expect(parser.matrix).to_not parse '((1, 2),)'
    end

    it 'parses arrays' do
      expect(parser.value).to parse '[1]'
      expect(parser.array).to parse '[]'
      expect(parser.array).to parse '[1]'
      expect(parser.array).to parse '[1, 2, 3, 4, 5]'
      expect(parser.array).to parse "[\n1 \n, \n2 , \n3\n]"
      expect(parser.array).to parse '[((1, 2), (3, 4))]'
      expect(parser.array).to parse '[[]]'
      expect(parser.array).to_not parse '[1,]'
    end

    it 'parses identifiers' do
      expect(parser.value).to parse 'id3n_tifier'
      expect(parser.identifier).to parse 'camelCase'
      expect(parser.identifier).to parse 'snake_case'
      expect(parser.identifier).to parse 'numb3rs'
      expect(parser.identifier).to parse 'ev3ry_th1ng'
      expect(parser.identifier).to_not parse ''
      expect(parser.identifier).to_not parse '3n'
    end
  end

  context 'errors' do
    it 'finds leaf with highest depth' do
      leaves = [[nil, 2], [nil, 1], [nil, 2], [nil, 0]]

      expect(parser.deepest_leaves leaves).to eql [[nil, 2], [nil, 2]]
    end

    it 'finds the deepest, left-most cause' do
      cause = Parslet::Cause.new(nil, nil, 0, [
        Parslet::Cause.new(nil, nil, 0, [
          Parslet::Cause.new(nil, nil, 0,
                             [Parslet::Cause.new(nil, nil, 1, [])])
        ]),
        Parslet::Cause.new(nil, nil, 0, [
          Parslet::Cause.new(nil, nil, 0,
                             [Parslet::Cause.new(nil, nil, 1, [])]),
          Parslet::Cause.new(nil, nil, 0,
                             [Parslet::Cause.new(nil, nil, 2, [])])
        ])
      ])

      expect(parser.deepest(cause)[0].pos).to eql 2
    end
  end
end
