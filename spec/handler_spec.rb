require File.join(File.dirname(__FILE__), 'spec_helper')

Otaku::Handler.class_eval do
  attr_reader :context, :proc
end

Otaku.instance_eval do
  def start(context = {}, &block)
    Otaku::Handler.new(context, block)
  end
end

class Otaku::Handler::Context
  alias_method :orig_magic_proc, :magic_proc
  attr_reader :magic_procs
  def magic_proc(val)
    (@magic_procs ||= []) << orig_magic_proc(val)
    @magic_procs.last
  end
end

describe "Otaku Service Handler" do

  describe '>> initializing @context' do

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

    describe '>>> handling serializing of proc variable' do

      class << self

        def new_otaku_handler(*args, &block)
          Otaku::Handler.new({:processor => block}, lambda{})
        end

        def should_have_expected_context(context, code, line)
          context.magic_procs[0].code.should.equal(code)
          context.magic_procs[0].file.should.equal(File.expand_path(__FILE__))
          context.magic_procs[0].line.should.equal(line)
        end

      end

      no_arg_expected = "lambda { [\"a\", \"b\"].map { |x| puts(x) } }"
      single_arg_expected = "lambda { |arg| [\"a\", \"b\"].map { |x| puts(x) } }"
      multiple_args_expected = "lambda { |arg1, arg2| [\"a\", \"b\"].map { |x| puts(x) } }"
      unlimited_args_expected = "lambda { |*args| [\"a\", \"b\"].map { |x| puts(x) } }"

      {
      # ////////////////////////////////////////////////////////////////////////
      # >> Always newlinling (single arg)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |arg|
            %w{a b}.map do |x|
              puts x
            end
          end,
          single_arg_expected
        ],
        __LINE__ => [
          lambda { |arg|
            %w{a b}.map{|x|
              puts x
            }
          },
          single_arg_expected
        ],
        __LINE__ => [
          proc do |arg|
            %w{a b}.map do |x|
              puts x
            end
          end,
          single_arg_expected
        ],
        __LINE__ => [
          lambda { |arg|
            %w{a b}.map{|x|
              puts x
            }
          },
          single_arg_expected
        ],
        __LINE__ => [
          Proc.new do |arg|
            %w{a b}.map do |x|
              puts x
            end
          end,
          single_arg_expected
        ],
        __LINE__ => [
          Proc.new { |arg|
            %w{a b}.map{|x|
              puts x
            }
          },
          single_arg_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Always newlinling (multiple args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |arg1, arg2|
            %w{a b}.map do |x|
              puts x
            end
          end,
          multiple_args_expected
        ],
        __LINE__ => [
          lambda { |arg1, arg2|
            %w{a b}.map{|x|
              puts x
            }
          },
          multiple_args_expected
        ],
        __LINE__ => [
          proc do |arg1, arg2|
            %w{a b}.map do |x|
              puts x
            end
          end,
          multiple_args_expected
        ],
        __LINE__ => [
          lambda { |arg1, arg2|
            %w{a b}.map{|x|
              puts x
            }
          },
          multiple_args_expected
        ],
        __LINE__ => [
          Proc.new do |arg1, arg2|
            %w{a b}.map do |x|
              puts x
            end
          end,
          multiple_args_expected
        ],
        __LINE__ => [
          Proc.new { |arg1, arg2|
            %w{a b}.map{|x|
              puts x
            }
          },
          multiple_args_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Always newlinling (unlimited args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |*args|
            %w{a b}.map do |x|
              puts x
            end
          end,
          unlimited_args_expected
        ],
        __LINE__ => [
          lambda { |*args|
            %w{a b}.map{|x|
              puts x
            }
          },
          unlimited_args_expected
        ],
        __LINE__ => [
          proc do |*args|
            %w{a b}.map do |x|
              puts x
            end
          end,
          unlimited_args_expected
        ],
        __LINE__ => [
          lambda { |*args|
            %w{a b}.map{|x|
              puts x
            }
          },
          unlimited_args_expected
        ],
        __LINE__ => [
          Proc.new do |*args|
            %w{a b}.map do |x|
              puts x
            end
          end,
          unlimited_args_expected
        ],
        __LINE__ => [
          Proc.new { |*args|
            %w{a b}.map{|x|
              puts x
            }
          },
          unlimited_args_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Always newlinling (no arg)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do
            %w{a b}.map do |x|
              puts x
            end
          end,
          no_arg_expected
        ],
        __LINE__ => [
          lambda {
            %w{a b}.map{|x|
              puts x
            }
          },
          no_arg_expected
        ],
        __LINE__ => [
          proc do
            %w{a b}.map do |x|
              puts x
            end
          end,
          no_arg_expected
        ],
        __LINE__ => [
          lambda {
            %w{a b}.map{|x|
              puts x
            }
          },
          no_arg_expected
        ],
        __LINE__ => [
          Proc.new do
            %w{a b}.map do |x|
              puts x
            end
          end,
          no_arg_expected
        ],
        __LINE__ => [
          Proc.new {
            %w{a b}.map{|x|
              puts x
            }
          },
          no_arg_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Partial newlining (single arg)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |arg|
            %w{a b}.map do |x| puts x end
          end,
          single_arg_expected
        ],
        __LINE__ => [
          lambda { |arg|
            %w{a b}.map{|x| puts x }
          },
          single_arg_expected
        ],
        __LINE__ => [
          proc do |arg|
            %w{a b}.map do |x| puts x end
          end,
          single_arg_expected
        ],
        __LINE__ => [
          lambda { |arg|
            %w{a b}.map{|x| puts x }
          },
          single_arg_expected
        ],
        __LINE__ => [
          Proc.new do |arg|
            %w{a b}.map do |x| puts x end
          end,
          single_arg_expected
        ],
        __LINE__ => [
          Proc.new { |arg|
            %w{a b}.map{|x| puts x }
          },
          single_arg_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Partial newlining (multiple args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |arg1, arg2|
            %w{a b}.map do |x| puts x end
          end,
          multiple_args_expected
        ],
        __LINE__ => [
          lambda { |arg1, arg2|
            %w{a b}.map{|x| puts x }
          },
          multiple_args_expected
        ],
        __LINE__ => [
          proc do |arg1, arg2|
            %w{a b}.map do |x| puts x end
          end,
          multiple_args_expected
        ],
        __LINE__ => [
          lambda { |arg1, arg2|
            %w{a b}.map{|x| puts x }
          },
          multiple_args_expected
        ],
        __LINE__ => [
          Proc.new do |arg1, arg2|
            %w{a b}.map do |x| puts x end
          end,
          multiple_args_expected
        ],
        __LINE__ => [
          Proc.new { |arg1, arg2|
            %w{a b}.map{|x| puts x }
          },
          multiple_args_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Partial newlining (unlimited args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |*args|
            %w{a b}.map do |x| puts x end
          end,
          unlimited_args_expected
        ],
        __LINE__ => [
          lambda { |*args|
            %w{a b}.map{|x| puts x }
          },
          unlimited_args_expected
        ],
        __LINE__ => [
          proc do |*args|
            %w{a b}.map do |x| puts x end
          end,
          unlimited_args_expected
        ],
        __LINE__ => [
          lambda { |*args|
            %w{a b}.map{|x| puts x }
          },
          unlimited_args_expected
        ],
        __LINE__ => [
          Proc.new do |*args|
            %w{a b}.map do |x| puts x end
          end,
          unlimited_args_expected
        ],
        __LINE__ => [
          Proc.new { |*args|
            %w{a b}.map{|x| puts x }
          },
          unlimited_args_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> Partial newlining (no args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do
            %w{a b}.map do |x| puts x end
          end,
          no_arg_expected
        ],
        __LINE__ => [
          lambda {
            %w{a b}.map{|x| puts x }
          },
          no_arg_expected
        ],
        __LINE__ => [
          proc do
            %w{a b}.map do |x| puts x end
          end,
          no_arg_expected
        ],
        __LINE__ => [
          lambda {
            %w{a b}.map{|x| puts x }
          },
          no_arg_expected
        ],
        __LINE__ => [
          Proc.new do
            %w{a b}.map do |x| puts x end
          end,
          no_arg_expected
        ],
        __LINE__ => [
          Proc.new {
            %w{a b}.map{|x| puts x }
          },
          no_arg_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> No newlining (single arg)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |arg| %w{a b}.map do |x| puts x end end,
          single_arg_expected
        ],
        __LINE__ => [
          lambda { |arg| %w{a b}.map{|x| puts x } },
          single_arg_expected
        ],
        __LINE__ => [
          proc do |arg| %w{a b}.map do |x| puts x end end,
          single_arg_expected
        ],
        __LINE__ => [
          lambda { |arg| %w{a b}.map{|x| puts x } },
          single_arg_expected
        ],
        __LINE__ => [
          Proc.new do |arg| %w{a b}.map do |x| puts x end end,
          single_arg_expected
        ],
        __LINE__ => [
          Proc.new { |arg| %w{a b}.map{|x| puts x } },
          single_arg_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> No newlining (multiple args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |arg1, arg2| %w{a b}.map do |x| puts x end end,
          multiple_args_expected
        ],
        __LINE__ => [
          lambda { |arg1, arg2| %w{a b}.map{|x| puts x } },
          multiple_args_expected
        ],
        __LINE__ => [
          proc do |arg1, arg2| %w{a b}.map do |x| puts x end end,
          multiple_args_expected
        ],
        __LINE__ => [
          lambda { |arg1, arg2| %w{a b}.map{|x| puts x } },
          multiple_args_expected
        ],
        __LINE__ => [
          Proc.new do |arg1, arg2| %w{a b}.map do |x| puts x end end,
          multiple_args_expected
        ],
        __LINE__ => [
          Proc.new { |arg1, arg2| %w{a b}.map{|x| puts x } },
          multiple_args_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> No newlining (unlimited args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do |*args| %w{a b}.map do |x| puts x end end,
          unlimited_args_expected
        ],
        __LINE__ => [
          lambda { |*args| %w{a b}.map{|x| puts x } },
          unlimited_args_expected
        ],
        __LINE__ => [
          proc do |*args| %w{a b}.map do |x| puts x end end,
          unlimited_args_expected
        ],
        __LINE__ => [
          lambda { |*args| %w{a b}.map{|x| puts x } },
          unlimited_args_expected
        ],
        __LINE__ => [
          Proc.new do |*args| %w{a b}.map do |x| puts x end end,
          unlimited_args_expected
        ],
        __LINE__ => [
          Proc.new { |*args| %w{a b}.map{|x| puts x } },
          unlimited_args_expected
        ],
      # ////////////////////////////////////////////////////////////////////////
      # >> No newlining (no args)
      # ////////////////////////////////////////////////////////////////////////
        __LINE__ => [
          lambda do %w{a b}.map do |x| puts x end end,
          no_arg_expected
        ],
        __LINE__ => [
          lambda { %w{a b}.map{|x| puts x } },
          no_arg_expected
        ],
        __LINE__ => [
          proc do %w{a b}.map do |x| puts x end end,
          no_arg_expected
        ],
        __LINE__ => [
          lambda { %w{a b}.map{|x| puts x } },
          no_arg_expected
        ],
        __LINE__ => [
          Proc.new do %w{a b}.map do |x| puts x end end,
          no_arg_expected
        ],
        __LINE__ => [
          Proc.new { %w{a b}.map{|x| puts x } },
          no_arg_expected
        ],
      }.each do |debug, (block, expected)|
        should "handle proc variable [##{debug}]" do
          magic_proc = Otaku::Handler::MagicProc.new(block)
          encoded = Otaku::Encoder.encode(magic_proc).gsub('|','\|')
          context = Otaku::Handler.new({:processor => block}, lambda{}).context
          context.code.should.equal \
            'Class.new{ %s }.new' % "def processor; Encoder.decode(%|#{encoded}|).eval!; end"
          should_have_expected_context(context, expected, debug.succ)
        end
      end

      # No args

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do
            %w{a b}.map{|x| puts x }
          end
        ).context, no_arg_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do
            %w{a b}.map{|x| puts x }
          end
        ).context, no_arg_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do
            %w{a b}.map{|x| puts x }
          end
        ).context, no_arg_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do %w{a b}.map{|x| puts x } end
        ).context, no_arg_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do %w{a b}.map{|x| puts x } end
        ).context, no_arg_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do %w{a b}.map{|x| puts x } end
        ).context, no_arg_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) {
            %w{a b}.map{|x| puts x }
          }
        ).context, no_arg_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler {
            %w{a b}.map{|x| puts x }
          }
        ).context, no_arg_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { %w{a b}.map{|x| puts x } }
        ).context, no_arg_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { %w{a b}.map{|x| puts x } }
        ).context, no_arg_expected, __LINE__ - 1)
      end

      # Single arg

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do |arg|
            %w{a b}.map{|x| puts x }
          end
        ).context, single_arg_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do |arg|
            %w{a b}.map{|x| puts x }
          end
        ).context, single_arg_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do |arg|
            %w{a b}.map{|x| puts x }
          end
        ).context, single_arg_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do |arg| %w{a b}.map{|x| puts x } end
        ).context, single_arg_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do |arg| %w{a b}.map{|x| puts x } end
        ).context, single_arg_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do |arg| %w{a b}.map{|x| puts x } end
        ).context, single_arg_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { |arg|
            %w{a b}.map{|x| puts x }
          }
        ).context, single_arg_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { |arg|
            %w{a b}.map{|x| puts x }
          }
        ).context, single_arg_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { |arg| %w{a b}.map{|x| puts x } }
        ).context, single_arg_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { |arg| %w{a b}.map{|x| puts x } }
        ).context, single_arg_expected, __LINE__ - 1)
      end

      # Multiple args

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do |arg1, arg2|
            %w{a b}.map{|x| puts x }
          end
        ).context, multiple_args_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do |arg1, arg2|
            %w{a b}.map{|x| puts x }
          end
        ).context, multiple_args_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do |arg1, arg2|
            %w{a b}.map{|x| puts x }
          end
        ).context, multiple_args_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do |arg1, arg2| %w{a b}.map{|x| puts x } end
        ).context, multiple_args_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do |arg1, arg2| %w{a b}.map{|x| puts x } end
        ).context, multiple_args_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do |arg1, arg2| %w{a b}.map{|x| puts x } end
        ).context, multiple_args_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { |arg1, arg2|
            %w{a b}.map{|x| puts x }
          }
        ).context, multiple_args_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { |arg1, arg2|
            %w{a b}.map{|x| puts x }
          }
        ).context, multiple_args_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { |arg1, arg2| %w{a b}.map{|x| puts x } }
        ).context, multiple_args_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { |arg1, arg2| %w{a b}.map{|x| puts x } }
        ).context, multiple_args_expected, __LINE__ - 1)
      end

      # Unlimited args

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do |*args|
            %w{a b}.map{|x| puts x }
          end
        ).context, unlimited_args_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do |*args|
            %w{a b}.map{|x| puts x }
          end
        ).context, unlimited_args_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do |*args|
            %w{a b}.map{|x| puts x }
          end
        ).context, unlimited_args_expected, __LINE__ - 3)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) do |*args| %w{a b}.map{|x| puts x } end
        ).context, unlimited_args_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler do |*args| %w{a b}.map{|x| puts x } end
        ).context, unlimited_args_expected, __LINE__ - 1)
      end

      should "handle block using do ... end [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler 1, 2 do |*args| %w{a b}.map{|x| puts x } end
        ).context, unlimited_args_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { |*args|
            %w{a b}.map{|x| puts x }
          }
        ).context, unlimited_args_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { |*args|
            %w{a b}.map{|x| puts x }
          }
        ).context, unlimited_args_expected, __LINE__ - 3)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler(1, 2) { |*args| %w{a b}.map{|x| puts x } }
        ).context, unlimited_args_expected, __LINE__ - 1)
      end

      should "handle block using { ... } [##{__LINE__}]" do
        should_have_expected_context((
          new_otaku_handler { |*args| %w{a b}.map{|x| puts x } }
        ).context, unlimited_args_expected, __LINE__ - 1)
      end

    end

  end

  describe '>> initializing @processor' do

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

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => lambda {'dummy'}) { |watever|
        %w{a b}.map do |x|
          puts x
        end
      }.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => proc {'dummy'}) { |watever|
        %w{a b}.map do |x|
          puts x
        end
      }.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => Proc.new {'dummy'}) { |watever|
        %w{a b}.map do |x|
          puts x
        end
      }.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => lambda {'dummy'}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => proc {'dummy'}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => proc {|arg| 'dummy'}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => proc {|arg1, arg2| 'dummy'}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => proc {|*args| 'dummy'}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

    should "handle block with context variable as proc [##{__LINE__}]" do
      Otaku.start(:processor => Proc.new {'dummy'}) do |watever|
        %w{a b}.map do |x|
          puts x
        end
      end.processor.code.should.equal(expected)
    end

  end

  describe '>> fetching root' do
    should 'return directory of current file' do
      Otaku.start { |watever| __LINE__ }.root.should.equal(File.expand_path(File.dirname(__FILE__)))
    end
  end

  describe '>> processing magic variables' do

    should "reflect __FILE__ captured when the proc was 1st defined [##{__LINE__}]" do
      Otaku.start(:processor => lambda { __FILE__ }) { |watever| processor.call }.
        process(:fake_data).should.equal(File.expand_path(__FILE__))
    end

    should "reflect __FILE__ captured when the proc was 1st defined [##{__LINE__}]" do
      Otaku.start{ |watever| __FILE__ }.process(:fake_data).should.equal(File.expand_path(__FILE__))
    end

    should "reflect __LINE__ captured when the proc was 1st defined [##{__LINE__}]" do
      Otaku.start(:processor => lambda { __LINE__ }) { |watever| processor.call }.
        process(:fake_data).should.equal(__LINE__.pred)
    end

    should "reflect __LINE__ captured when the proc was 1st defined [##{__LINE__}]" do
      Otaku.start{ |watever| __LINE__ }.process(:fake_data).should.equal(__LINE__)
    end

  end

end
