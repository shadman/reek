require_relative '../../spec_helper'
require_lib 'reek/smells/too_many_instance_variables'

RSpec.describe Reek::Smells::TooManyInstanceVariables do
  it 'reports the right values' do
    src = <<-EOS
      class Alfa
        def bravo
          @charlie = @delta = @echo = @foxtrot = 1
          @golf = 1
        end
      end
    EOS

    expect(src).to reek_of(:TooManyInstanceVariables,
                           lines:   [1],
                           context: 'Alfa',
                           message: 'has at least 5 instance variables',
                           source:  'string',
                           count:   5)
  end

  context 'counting instance variables' do
    it 'does not report for non-excessive ivars' do
      src = <<-EOS
        class Alfa
          def bravo
          @charlie = @delta = @echo = @foxtrot = 1
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end

    it 'has a configurable maximum' do
      src = <<-EOS
        # :reek:TooManyInstanceVariables: { max_instance_variables: 5 }
        class Alfa
          def bravo
            @charlie = @delta = @echo = @foxtrot = 1
            @golf = 1
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end

    it 'counts each ivar only once' do
      src = <<-EOS
        class Alfa
          def bravo
            @charlie = @delta = @echo = @foxtrot = 1
            @charlie = @delta = @echo = @foxtrot = 1
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end

    it 'does not report memoized bravo' do
      src = <<-EOS
        class Alfa
          def bravo
            @charlie = @delta = @echo = @foxtrot = 1
            @golf ||= 1
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end

    it 'does not count bravo on inner classes altogether' do
      src = <<-EOS
        class Alfa
          class Bravo
            def charlie
              @delta = @echo = @foxtrot = @golf = 1
            end
          end

          class Hotel
            def india
              @juliett = 1
            end
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end

    it 'does not count bravo on modules altogether' do
      src = <<-EOS
        class Alfa
          class Bravo
            def charlie
              @delta = @echo = @foxtrot = @golf = 1
            end
          end

          module Hotel
            def india
              @juliett = 1
            end
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end

    it 'reports excessive ivars even in different methods' do
      src = <<-EOS
        class Alfa
          def bravo
            @charlie = @delta = @echo = @foxtrot = 1
          end

          def golf
            @hotel = 1
          end
        end
      EOS

      expect(src).to reek_of(:TooManyInstanceVariables)
    end

    it 'does not report for ivars in 2 extensions' do
      src = <<-EOS
        class Alfa
          def bravo
            @charlie = @delta = @echo = @foxtrot = 1
          end
        end

        class Golf
          def hotel
            @india = @juliett = @kilo = @lima = 1
          end
        end
      EOS

      expect(src).not_to reek_of(:TooManyInstanceVariables)
    end
  end
end
