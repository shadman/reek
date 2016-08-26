require_relative '../../spec_helper'

require_lib 'reek/smells/instance_variable_assumption'

RSpec.describe Reek::Smells::InstanceVariableAssumption do
  it 'reports the right values' do
    src = <<-EOS
      class Dummy
        def meth
          @a
        end
      end
    EOS

    expect(src).to reek_of(:InstanceVariableAssumption,
                           lines:      [1],
                           context:    'Dummy',
                           message:    'assumes too much for instance variable @a',
                           source:     'string',
                           assumption: :@a)
  end

  it 'does count all occurences' do
    src = <<-EOS
      class Dummy
        def meth_1
          @a
        end

        def meth_2
          @b
        end
      end

    EOS

    expect(src).
      to reek_of(:InstanceVariableAssumption, lines: [1], assumption: :@a).
      and reek_of(:InstanceVariableAssumption, lines: [1], assumption: :@b)
  end

  it 'reports each ivar separately' do
    src = <<-EOS
      class Dummy
        def test
          [@a, @a, @b, @c]
        end

        def retest
          @c
        end
      end
    EOS

    expect(src).
      to reek_of(:InstanceVariableAssumption, assumption: :@a).
      and reek_of(:InstanceVariableAssumption, assumption: :@b).
      and reek_of(:InstanceVariableAssumption, assumption: :@c)
  end

  it 'does not report an empty class' do
    src = <<-EOS
      class Dummy
      end
    EOS

    expect(src).not_to reek_of(:InstanceVariableAssumption)
  end

  it 'does not report when lazy initializing' do
    src = <<-EOS
      class Dummy
        def test
          @a ||= 1
        end
      end
    EOS

    expect(src).not_to reek_of(:InstanceVariableAssumption)
  end

  it 'reports when making instance variable assumption' do
    src = <<-EOS
      class Dummy
        def test
          @a
        end
      end
    EOS

    expect(src).to reek_of(:InstanceVariableAssumption)
  end

  it 'reports variable even if others are initialized' do
    src = <<-EOS
      class Dummy
        def initialize
          @a = 1
        end

        def test
          [@a, @b]
        end
      end
    EOS

    expect(src).to reek_of(:InstanceVariableAssumption)
  end

  context 'inner classes' do
    it 'reports outer class' do
      src = <<-EOS
        class Dummy
          def test
            @a
          end

          class Dummiest
          end
        end
      EOS

      expect(src).to reek_of(:InstanceVariableAssumption, context: 'Dummy')
    end

    it 'reports inner class even if outer class initializes the variable' do
      src = <<-EOS
        class Dummy
          def initialize
            @a = 1
          end

          class Dummiest
            def test
              @a
            end
          end
        end
      EOS

      expect(src).to reek_of(:InstanceVariableAssumption, context: 'Dummy::Dummiest')
    end

    it 'reports inner classes' do
      src = <<-EOS
        class Dummy
          class Dummiest
            def initialize
              @b = 1
            end

            def test
              @c
            end
          end
        end
      EOS

      expect(src).to reek_of(:InstanceVariableAssumption, context: 'Dummy::Dummiest')
    end
  end
end
