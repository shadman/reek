require_relative '../../spec_helper'
require_lib 'reek/smells/feature_envy'

RSpec.describe Reek::Smells::FeatureEnvy do
  it 'reports the right values' do
    src = <<-EOS
      class Alfa
        def bravo(charlie)
          (charlie.delta - charlie.echo) * foxtrot
        end
      end
    EOS

    expect(src).to reek_of(:FeatureEnvy,
                           lines:   [3, 3],
                           context: 'Alfa#bravo',
                           message: 'refers to charlie more than self (maybe move it to another class?)',
                           source:  'string',
                           name:    'charlie')
  end

  it 'does count all occurences' do
    src = <<-EOS
      class Alfa
        def bravo(charlie)
          (charlie.delta - charlie.echo) * foxtrot
        end

        def golf(hotel)
          (hotel.india + hotel.juliett) * kilo
        end
      end
    EOS

    expect(src).to reek_of(:FeatureEnvy,
                           lines: [3, 3],
                           name:  'charlie')
    expect(src).to reek_of(:FeatureEnvy,
                           lines: [7, 7],
                           name:  'hotel')
  end

  it 'does not report use of self' do
    expect('def alfa; self.to_s + self.to_i; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report vcall with no argument' do
    expect('def alfa; bravo; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report single use' do
    expect('def alfa(bravo); bravo.charlie(@delta); end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report return value' do
    expect('def alfa(bravo); bravo.charlie(@delta); bravo; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does ignore global variables' do
    expect('def alfa; $bravo.to_a; $bravo[@charlie]; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report class methods' do
    expect('def alfa; self.class.bravo(self); end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report single use of an ivar' do
    expect('def alfa; @bravo.to_a; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report returning an ivar' do
    expect('def alfa; @bravo.to_a; @bravo; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report ivar usage in a parameter' do
    expect('def alfa; @bravo.charlie + delta(@bravo) - echo(@bravo) end').
      not_to reek_of(:FeatureEnvy)
  end

  it 'does not report single use of an lvar' do
    expect('def alfa; bravo = @charlie; bravo.to_a; end').not_to reek_of(:FeatureEnvy)
  end

  it 'does not report returning an lvar' do
    expect('def alfa; bravo = @charlie; bravo.to_a; lv end').not_to reek_of(:FeatureEnvy)
  end

  it 'ignores lvar usage in a parameter' do
    expect('def alfa; bravo = @item; bravo.charlie + delta(bravo) - echo(bravo); end').
      not_to reek_of(:FeatureEnvy)
  end

  it 'ignores multiple ivars' do
    src = <<-EOS
      def func
        @alfa.charlie
        @alfa.delta

        @bravo.echo
        @bravo.foxtrot
      end
    EOS

    expect(src).not_to reek_of(:FeatureEnvy)
  end

  it 'report highest affinity' do
    src = <<-EOS
      def alfa
        bravo = @charlie
        delta = 0
        delta += bravo.echo
        delta += bravo.foxtrot
        delta *= 1.15
      end
      EOS

    expect(src).to reek_of(:FeatureEnvy, name: 'delta')
    expect(src).not_to reek_of(:FeatureEnvy, name: 'bravo')
  end

  it 'should report multiple affinities' do
    src = <<-EOS
      def alfa
        bravo = @charlie
        delta = 0
        delta += bravo.echo
        delta += bravo.foxtrot
      end
      EOS

    expect(src).to reek_of(:FeatureEnvy, name: 'delta')
    expect(src).to reek_of(:FeatureEnvy, name: 'bravo')
  end

  it 'is not be fooled by duplication' do
    src = <<-EOS
      def alfa(bravo)
        @charlie.delta(bravo.echo)
        @foxtrot.delta(bravo.echo)
      end
    EOS

    expect(src).to reek_only_of(:DuplicateMethodCall)
  end

  it 'does not count local calls' do
    src = <<-EOS
      def alfa(bravo)
        @charlie.delta(bravo.echo)
        @foxtrot.delta(bravo.echo)
      end
    EOS

    expect(src).to reek_only_of(:DuplicateMethodCall)
  end

  it 'reports many calls to lvar' do
    src = <<-EOS
      def alfa
        bravo = @charlie
        bravo.delta + bravo.echo
      end
    EOS

    expect(src).to reek_only_of(:FeatureEnvy)
  end

  it 'counts =~ as a call' do
    src = <<-EOS
      def alfa(bravo)
        charlie(bravo.delta)
        bravo =~ /charlie/
      end
    EOS

    expect(src).to reek_of :FeatureEnvy
  end

  it 'counts += as a call' do
    src = <<-EOS
      def alfa(bravo)
        charlie(bravo.delta)
        bravo += 1
      end
    EOS

    expect(src).to reek_of :FeatureEnvy
  end

  it 'counts ivar assignment as call to self' do
    src = <<-EOS
      def foo
        bravo = charlie(1, 2)

        @delta = bravo.echo
        @foxtrot = bravo.golf
      end
    EOS

    expect(src).not_to reek_of :FeatureEnvy
  end

  it 'counts self references correctly' do
    src = <<-EOS
      def alfa(bravo)
        bravo.keys.each do |charlie|
          self[charlie] += 3
          self[charlie] = 4
        end
        self
      end
    EOS

    expect(src).not_to reek_of(:FeatureEnvy)
  end

  it 'interprets << correctly' do
    src = <<-EOS
      def alfa(bravo)
        if @charlie
          bravo.delta(self)
        else
          bravo << self
        end
      end
    EOS

    expect(src).not_to reek_of(:FeatureEnvy)
  end
end
