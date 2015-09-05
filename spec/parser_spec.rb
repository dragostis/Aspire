require 'parslet/rig/rspec'

require_relative '../parser'

describe Parser do
  let(:parser) { Parser.new }

  context 'values' do
    let(:value_parser) { parser.value }

    it 'parses booleans' do
      expect(value_parser).to parse('true')
      expect(value_parser).to parse('false')
    end

    it 'parses integers' do
      expect(value_parser).to parse('0')
      expect(value_parser).to parse('10')
      expect(value_parser).to parse('1234567890')
      expect(value_parser).to parse('-10')
      expect(value_parser).to parse('+10')
      expect(value_parser).to_not parse('010')
    end

    it 'parses floats' do
      expect(value_parser).to parse('0.')
      expect(value_parser).to parse('.0')
      expect(value_parser).to parse('1234567890.1234567890')
      expect(value_parser).to parse('-0.0')
      expect(value_parser).to parse('+0.0')
      expect(value_parser).to parse('0.0e+10')
      expect(value_parser).to parse('0.0e-10')
      expect(value_parser).to parse('-0.0E-10')
      expect(value_parser).to_not parse('00.0')
      expect(value_parser).to_not parse('0.0e-00')
    end

    it 'parses colors' do
      expect(value_parser).to parse('#000')
      expect(value_parser).to parse('#000000')
      expect(value_parser).to parse('#fff')
      expect(value_parser).to parse('#FFFFFF')
      expect(value_parser).to parse('#FFFFFF00')
      expect(value_parser).to_not parse('#ggg')
      expect(value_parser).to_not parse('#ffff')
      expect(value_parser).to_not parse('#fffff')
      expect(value_parser).to_not parse('#fffffff')
    end

    it 'parses identifiers' do
      expect(value_parser).to parse('camelCase')
      expect(value_parser).to parse('snake_case')
      expect(value_parser).to parse('numb3rs')
      expect(value_parser).to parse('ev3ry_th1ng')
      expect(value_parser).to_not parse('')
      expect(value_parser).to_not parse('3n')
    end
  end
end
