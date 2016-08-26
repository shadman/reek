require_relative '../../spec_helper'
require_lib 'reek/smells/feature_envy'

RSpec::Matchers.define_negated_matcher :not_reek_of, :reek_of

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

    expect(src).
      to reek_of(:FeatureEnvy, lines: [3, 3], name:  'charlie').
      and reek_of(:FeatureEnvy, lines: [7, 7], name:  'hotel')
  end

  context 'with no smell' do
    it 'does not report use of self' do
      src = <<-EOS
        def simple()
          self.to_s + self.to_i
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report vcall with no argument' do
      src = <<-EOS
        def simple()
          func
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report single use' do
      src = <<-EOS
        def no_envy(arga)
          arga.barg(@item)
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report return value' do
      src = <<-EOS
        def no_envy(arga)
          arga.barg(@item)
          arga
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'ignores global variables' do
      src = <<-EOS
        def no_envy()
          $s2.to_a
          $s2[@item]
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report class methods' do
      src = <<-EOS
        def simple()
          self.class.new.flatten_merge(self)
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report single use of an ivar' do
      src = <<-EOS
        def no_envy()
          @item.to_a
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report returning an ivar' do
      src = <<-EOS
        def no_envy()
          @item.to_a
          @item
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report ivar usage in a parameter' do
      src = <<-EOS
        def no_envy()
          @item.price + tax(@item) - savings(@item)
        end
      EOS
      expect(src).
        not_to reek_of(:FeatureEnvy)
    end

    it 'does not report single use of an lvar' do
      src = <<-EOS
        def no_envy()
          lv = @item
          lv.to_a
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'does not report returning an lvar' do
      src = <<-EOS
        def no_envy()
          lv = @item
          lv.to_a
          lv
        end
      EOS
      expect(src).not_to reek_of(:FeatureEnvy)
    end

    it 'ignores lvar usage in a parameter' do
      src = <<-EOS
        def no_envy()
          lv = @item
          lv.price + tax(lv) - savings(lv)
        end
      EOS
      expect(src).
        not_to reek_of(:FeatureEnvy)
    end

    it 'ignores multiple ivars' do
      src = <<-EOS
        def func
          @other.a
          @other.b
          @nother.c
          @nother.d
        end
      EOS

      expect(src).not_to reek_of(:FeatureEnvy)
    end
  end

  context 'with 2 calls to a parameter' do
    it 'reports the smell' do
      src = <<-EOS
        def envy(arga)
          arga.b(arga) + arga.c(@fred)
        end
      EOS

      expect(src).to reek_of(:FeatureEnvy, name: 'arga')
    end
  end

  it 'reports highest affinity' do
    src = <<-EOS
      def total_envy
        fred = @item
        total = 0
        total += fred.price
        total += fred.tax
        total *= 1.15
      end
      EOS

    expect(src).
      to reek_of(:FeatureEnvy, name: 'total').
      and not_reek_of(:FeatureEnvy, name: 'fred')
  end

  it 'reports multiple affinities' do
    src = <<-EOS
      def total_envy
        fred = @item
        total = 0
        total += fred.price
        total += fred.tax
      end
      EOS

    expect(src).
      to reek_of(:FeatureEnvy, name: 'total').
      and reek_of(:FeatureEnvy, name: 'fred')
  end

  it 'is not fooled by duplication' do
    src = <<-EOS
      def feed(thing)
        @cow.feed_to(thing.pig)
        @duck.feed_to(thing.pig)
      end
    EOS

    expect(src).to reek_only_of(:DuplicateMethodCall)
  end

  it 'counts local calls' do
    src = <<-EOS
      def feed(thing)
        cow.feed_to(thing.pig)
        duck.feed_to(thing.pig)
      end
    EOS

    expect(src).to reek_only_of(:DuplicateMethodCall)
  end

  it 'reports many calls to lvar' do
    src = <<-EOS
      def envy()
        lv = @item
        lv.price + lv.tax
      end
    EOS

    expect(src).to reek_only_of(:FeatureEnvy)
  end

  it 'ignores frequent use of a call' do
    src = <<-EOS
      def func()
        other.a
        other.b
        nother.c
      end
    EOS
    expect(src).not_to reek_of(:FeatureEnvy)
  end

  it 'counts =~ as a call' do
    src = <<-EOS
      def foo arg
        bar(arg.baz)
        arg =~ /bar/
      end
    EOS

    expect(src).to reek_of :FeatureEnvy
  end

  it 'counts += as a call' do
    src = <<-EOS
      def foo arg
        bar(arg.baz)
        arg += 1
      end
    EOS

    expect(src).to reek_of :FeatureEnvy
  end

  it 'counts ivar assignment as call to self' do
    src = <<-EOS
      def foo
        bar = baz(1, 2)

        @quuz = bar.qux
        @zyxy = bar.foobar
      end
    EOS

    expect(src).not_to reek_of :FeatureEnvy
  end

  it 'counts self references correctly' do
    src = <<-EOS
      def adopt(other)
        other.keys.each do |key|
          self[key] += 3
          self[key] = o4
        end
        self
      end
    EOS

    expect(src).not_to reek_of(:FeatureEnvy)
  end

  it 'counts references to self correctly' do
    src = <<-EOS
      def report
        unless @report
          @report = Report.new
          cf = SmellConfig.new
          cf = cf.load_local(@dir) if @dir
          ContextBuilder.new(@report, cf.smell_listeners).check_source(@source)
        end
        @report
      end
    EOS

    expect(src).not_to reek_of(:FeatureEnvy)
  end

  it 'interprets << correctly' do
    src = <<-EOS
      def report_on(report)
        if @is_doubled
          report.record_doubled_smell(self)
        else
          report << self
        end
      end
    EOS

    expect(src).not_to reek_of(:FeatureEnvy)
  end
end
