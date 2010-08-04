require File.join(File.dirname(__FILE__), 'spec_helper')

Otaku::Handler.class_eval do
  attr_reader :context, :proc
end

Otaku.instance_eval do
  def start(context = {}, &block)
    Otaku::Handler.new({}, block)
  end
end

describe "Otaku Service Handler" do

  describe '>> initializing context' do

    should 'assign to empty anoynmous class instance code when given {}' do
      Otaku::Handler.new({}, lambda{}).context.code.should.equal('Class.new{  }.new')
    end

    should 'assign to non-empty anoynmous class instance code when given {:m1 => v1, :m2 => v2, ...}' do
      encode = lambda{|val| Otaku::Encoder.encode(val).gsub('|','\|') }
      Otaku::Handler.new({:m1 => 'v|1', :m2 => 'v|2'}, lambda{}).context.code.should.equal(
        'Class.new{ %s; %s }.new' % [
          "def m1; Encoder.decode(%|#{encode['v|1']}|); end",
          "def m2; Encoder.decode(%|#{encode['v|2']}|); end"
      ])
    end

  end

  describe '>> initializing proc' do

    expected = "lambda { |watever| [\"a\", \"b\"].map { |x| puts(x) } }"

    {
    # ////////////////////////////////////////////////////////////////////////
    # >> Always newlinling
    # ////////////////////////////////////////////////////////////////////////
      __LINE__ => (
        lambda do |watever|
          %w{a b}.map do |x|
            puts x
          end
        end
      ),
      __LINE__ => (
        lambda { |watever|
          %w{a b}.map{|x|
            puts x
          }
        }
      ),
      __LINE__ => (
        proc do |watever|
          %w{a b}.map do |x|
            puts x
          end
        end
      ),
      __LINE__ => (
        lambda { |watever|
          %w{a b}.map{|x|
            puts x
          }
        }
      ),
      __LINE__ => (
        Proc.new do |watever|
          %w{a b}.map do |x|
            puts x
          end
        end
      ),
      __LINE__ => (
        Proc.new { |watever|
          %w{a b}.map{|x|
            puts x
          }
        }
      ),
    # ////////////////////////////////////////////////////////////////////////
    # >> Partial newlining
    # ////////////////////////////////////////////////////////////////////////
      __LINE__ => (
        lambda do |watever|
          %w{a b}.map do |x| puts x end
        end
      ),
      __LINE__ => (
        lambda { |watever|
          %w{a b}.map{|x| puts x }
        }
      ),
      __LINE__ => (
        proc do |watever|
          %w{a b}.map do |x| puts x end
        end
      ),
      __LINE__ => (
        lambda { |watever|
          %w{a b}.map{|x| puts x }
        }
      ),
      __LINE__ => (
        Proc.new do |watever|
          %w{a b}.map do |x| puts x end
        end
      ),
      __LINE__ => (
        Proc.new { |watever|
          %w{a b}.map{|x| puts x }
        }
      ),
    # ////////////////////////////////////////////////////////////////////////
    # >> No newlining
    # ////////////////////////////////////////////////////////////////////////
      __LINE__ => (
        lambda do |watever| %w{a b}.map do |x| puts x end end
      ),
      __LINE__ => (
        lambda { |watever| %w{a b}.map{|x| puts x } }
      ),
      __LINE__ => (
        proc do |watever| %w{a b}.map do |x| puts x end end
      ),
      __LINE__ => (
        lambda { |watever| %w{a b}.map{|x| puts x } }
      ),
      __LINE__ => (
        Proc.new do |watever| %w{a b}.map do |x| puts x end end
      ),
      __LINE__ => (
        Proc.new { |watever| %w{a b}.map{|x| puts x } }
      ),
    }.each do |debug, block|
      should "handle proc as variable [##{debug}]" do
        Otaku::Handler.new({}, block).processor.code.should.equal(expected)
      end
    end

    should "handle block using do ... end [##{__LINE__}]" do
      Otaku.start({}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block using do ... end [##{__LINE__}]" do
      Otaku.start do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block using do ... end [##{__LINE__}]" do
      Otaku.start({}) do |watever|
        %w{a b}.map do |x| puts x end
      end.processor.code.should.equal(expected)
    end

    should "handle block using do ... end [##{__LINE__}]" do
      Otaku.start do |watever|
        %w{a b}.map do |x| puts x end
      end.processor.code.should.equal(expected)
    end

    should "handle block using do ... end [##{__LINE__}]" do
      Otaku.start({}) do |watever| %w{a b}.map do |x| puts x end end.
        processor.code.should.equal(expected)
    end

    should "handle block using do ... end [##{__LINE__}]" do
      Otaku.start do |watever| %w{a b}.map do |x| puts x end end.
        processor.code.should.equal(expected)
    end

    should "handle block using { ... } [##{__LINE__}]" do
      Otaku.start({}) { |watever|
        %w{a b}.map do |x|
          puts x
        end
      }.processor.code.should.equal(expected)
    end

    should "handle block using { ... } [##{__LINE__}]" do
      Otaku.start { |watever|
        %w{a b}.map do |x|
          puts x
        end
      }.processor.code.should.equal(expected)
    end

    should "handle block using { ... } [##{__LINE__}]" do
      Otaku.start({}) { |watever|
        %w{a b}.map { |x| puts x }
      }.processor.code.should.equal(expected)
    end

    should "handle block using { ... } [##{__LINE__}]" do
      Otaku.start { |watever|
        %w{a b}.map { |x| puts x }
      }.processor.code.should.equal(expected)
    end

    should "handle block using { ... } [##{__LINE__}]" do
      Otaku.start({}) { |watever| %w{a b}.map { |x| puts x } }.processor.code.should.equal(expected)
    end

    should "handle block using { ... } [##{__LINE__}]" do
      Otaku.start { |watever| %w{a b}.map { |x| puts x } }.processor.code.should.equal(expected)
    end

    should "leave __FILE__ as __FILE__ [##{__LINE__}]" do
      Otaku.start { |watever| __FILE__ }.processor.code.should.
        equal("lambda { |watever| __FILE__ }" % File.expand_path('spec/handler_spec.rb'))
    end

    should "leave __LINE__ as __LINE__ [##{__LINE__}]" do
      Otaku.start { |watever| __LINE__ }.processor.code.should.
        equal("lambda { |watever| __LINE__ }")
    end

  end

  describe '>> fetching root' do
    should 'return directory of current file' do
      Otaku.start { |watever| __LINE__ }.root.should.equal(File.expand_path(File.dirname(__FILE__)))
    end
  end

  describe '>> processing specified data' do

    should 'reflect __FILE__ captured when the proc was 1st defined' do
      Otaku.start{ |watever| __FILE__ }.process(:fake_data).should.equal(File.expand_path(__FILE__))
    end

    should 'reflect __LINE__ captured when the proc was 1st defined' do
      Otaku.start{ |watever| __LINE__ }.process(:fake_data).should.equal(__LINE__)
    end

  end

end
