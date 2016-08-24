require_relative '../../spec_helper'
require_lib 'reek/smells/duplicate_method_call'

RSpec.describe Reek::Smells::DuplicateMethodCall do
  it 'reports the right values' do
    src = <<-EOS
      class Alfa
        def bravo(charlie)
          charlie.delta
          charlie.delta
        end
      end
    EOS

    expect(src).to reek_of(:DuplicateMethodCall,
                           lines:   [3, 4],
                           context: 'Alfa#bravo',
                           message: 'calls charlie.delta 2 times',
                           source:  'string',
                           name:    'charlie.delta',
                           count:   2)
  end

  it 'does count all occurences' do
    src = <<-EOS
      class Alfa
        def bravo(charlie)
          charlie.delta
          charlie.delta
        end

        def echo(foxtrot)
          foxtrot.golf
          foxtrot.golf
        end
      end
    EOS

    expect(src).to reek_of(:DuplicateMethodCall,
                           lines: [3, 4],
                           name:  'charlie.delta',
                           count: 2)
    expect(src).to reek_of(:DuplicateMethodCall,
                           lines: [8, 9],
                           name:  'foxtrot.golf',
                           count: 2)
  end

  context 'with repeated method calls' do
    it 'reports repeated call to lvar' do
      src = 'def alfa(bravo); bravo.charlie + bravo.charlie; end'
      expect(src).to reek_of(:DuplicateMethodCall, name: 'bravo.charlie')
    end

    it 'reports call parameters' do
      src = 'def alfa; @bravo.charlie(2, 3) + @bravo.charlie(2, 3); end'
      expect(src).to reek_of(:DuplicateMethodCall, name: '@bravo.charlie(2, 3)')
    end

    it 'should report nested calls' do
      src = 'def alfa; @bravo.charlie.delta + @bravo.charlie.delta; end'
      expect(src).to reek_of(:DuplicateMethodCall, name: '@bravo.charlie')
      expect(src).to reek_of(:DuplicateMethodCall, name: '@bravo.charlie.delta')
    end

    it 'should ignore calls to new' do
      src = 'def alfa; @bravo.new + @bravo.new; end'
      expect(src).not_to reek_of(:DuplicateMethodCall)
    end
  end

  context 'with repeated simple method calls' do
    it 'reports no smell' do
      src = <<-EOS
        def alfa
          bravo
          bravo
        end
      EOS

      expect(src).not_to reek_of(:DuplicateMethodCall)
    end
  end

  context 'with repeated simple method calls with blocks' do
    it 'reports a smell if the blocks are identical' do
      src = <<-EOS
        def foo
          bar { baz }
          bar { baz }
        end
      EOS

      expect(src).to reek_of(:DuplicateMethodCall)
    end

    it 'reports no smell if the blocks are different' do
      src = <<-EOS
        def foo
          bar { baz }
          bar { qux }
        end
      EOS

      expect(src).not_to reek_of(:DuplicateMethodCall)
    end
  end

  context 'with repeated method calls with receivers with blocks' do
    it 'reports a smell if the blocks are identical' do
      src = <<-EOS
        def foo
          bar.qux { baz }
          bar.qux { baz }
        end
      EOS

      expect(src).to reek_of(:DuplicateMethodCall)
    end

    it 'reports a smell if the blocks are different' do
      src = <<-EOS
        def foo
          bar.qux { baz }
          bar.qux { qux }
        end
      EOS

      expect(src).to reek_of(:DuplicateMethodCall)
    end
  end

  context 'with repeated attribute assignment' do
    it 'reports repeated assignment' do
      src = 'def double_thing(thing) @other[thing] = true; @other[thing] = true; end'
      expect(src).to reek_of(:DuplicateMethodCall, name: '@other[thing] = true')
    end

    it 'does not report multi-assignments' do
      src = <<-EOS
        def _parse ctxt
          ctxt.index, result = @ind, @result
          error, ctxt.index = @err, @err_ind
        end
      EOS

      expect(src).not_to reek_of(:DuplicateMethodCall)
    end
  end

  context 'non-repeated method calls' do
    it 'should not report similar calls' do
      src = 'def equals(other) other.thing == self.thing end'
      expect(src).not_to reek_of(:DuplicateMethodCall)
    end

    it 'should respect call parameters' do
      src = 'def double_thing() @other.thing(3) + @other.thing(2) end'
      expect(src).not_to reek_of(:DuplicateMethodCall)
    end
  end

  context 'allowing up to 3 calls' do
    let(:config) do
      { Reek::Smells::DuplicateMethodCall::MAX_ALLOWED_CALLS_KEY => 3 }
    end

    it 'does not report double calls' do
      src = 'def double_thing() @other.thing + @other.thing end'
      expect(src).not_to reek_of(:DuplicateMethodCall).with_config(config)
    end

    it 'does not report triple calls' do
      src = 'def double_thing() @other.thing + @other.thing + @other.thing end'
      expect(src).not_to reek_of(:DuplicateMethodCall).with_config(config)
    end

    it 'reports quadruple calls' do
      src = <<-EOS
        def double_thing()
          @other.thing + @other.thing + @other.thing + @other.thing
        end
      EOS

      expect(src).to reek_of(:DuplicateMethodCall,
                             name: '@other.thing', count: 4).with_config(config)
    end
  end

  context 'allowing calls to some methods' do
    let(:config) do
      { Reek::Smells::DuplicateMethodCall::ALLOW_CALLS_KEY => ['@some.thing', /puts/] }
    end

    it 'does not report calls to some methods' do
      src = 'def double_some_thing() @some.thing + @some.thing end'
      expect(src).not_to reek_of(:DuplicateMethodCall).with_config(config)
    end

    it 'reports calls to other methods' do
      src = 'def double_other_thing() @other.thing + @other.thing end'
      expect(src).to reek_of(:DuplicateMethodCall, name: '@other.thing').with_config(config)
    end

    it 'does not report calls to methods specifed with a regular expression' do
      src = 'def double_puts() puts @other.thing; puts @other.thing end'
      expect(src).to reek_of(:DuplicateMethodCall, name: '@other.thing').with_config(config)
    end
  end
end
