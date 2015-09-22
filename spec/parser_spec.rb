require 'parslet'
require 'parslet/rig/rspec'

require_relative '../parser'

describe Parser do
  let(:parser) { Parser.new }

  context 'values' do
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
      expect(parser.float).to parse '0.0e+10'
      expect(parser.float).to parse '0.0e-10'
      expect(parser.float).to parse '-0.0E-10'
      expect(parser.float).to_not parse '00.0'
      expect(parser.float).to_not parse '0.0e-00'
    end

    it 'parses colors' do
      expect(parser.value).to parse '#fff'
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
    end

    it 'parses matrices' do
      expect(parser.value).to parse '((0, 0), (0, 0))'
      expect(parser.matrix).to parse '((1, 2), (3, 4))'
      expect(parser.matrix).to parse '((1, 2), (3, 4), (1, 2), (3, 4))'
      expect(parser.matrix).to parse "((\n1 \n, \n2 , \n3\n)\n, \n(4, 5))"
      expect(parser.matrix).to_not parse '((1, 2))'
    end

    it 'parses arrays' do
      expect(parser.value).to parse '[1]'
      expect(parser.array).to parse '[]'
      expect(parser.array).to parse '[1]'
      expect(parser.array).to parse '[1, 2, 3, 4, 5]'
      expect(parser.array).to parse "[\n1 \n, \n2 , \n3\n]"
      expect(parser.array).to parse '[((1, 2), (3, 4))]'
      expect(parser.array).to parse '[[]]'
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
