module Otaku
  class Handler

    def initialize(context, handler)
      @context = __context_as_code__(context)
      magic_proc = MagicProc.new(handler)
      @proc, @file, @line = [:code, :file, :line].map{|meth| magic_proc.send(meth) }
    end

    def process(data)
      (instance = eval(@context, nil, '(generated class)', 1)).
        instance_exec(data, &(block = eval(@proc, nil, @file, @line)))
    end

    def root
      File.dirname(@file)
    end

    private

      def __context_as_code__(methods_hash)
        'Class.new{ %s }.new' %
          methods_hash.map do |method, val|
            "def #{method}; Encoder.decode(%|#{Encoder.encode(val).gsub('|','\|')}|); end"
          end.sort.join('; ')
      end

      class MagicProc

        RUBY_PARSER = RubyParser.new
        RUBY_2_RUBY = Ruby2Ruby.new

        attr_reader :file, :line, :code

        def initialize(block)
          @block = block
          extract_file_and_line_and_code
        end

        private

          def extract_file_and_line_and_code
            code, remaining = code_fragments

            while frag = remaining[frag_regexp,1]
              begin
                sexp = RUBY_PARSER.parse(replace_magic_vars(code += frag))
                if sexp.inspect =~ sexp_regexp
                  @code = revert_magic_vars(RUBY_2_RUBY.process(sexp)).sub('proc {','lambda {')
                  break
                end
              rescue SyntaxError, Racc::ParseError, NoMethodError
                remaining.sub!(frag,'')
              end
            end
          end

          def code_fragments
            ignore, start_marker, arg =
              [:ignore, :start_marker, :arg].map{|key| code_match_args[key] }
            [
              "proc #{start_marker} |#{arg}| ",
              source_code.sub(ignore, '')
            ]
          end

          def sexp_regexp
            @sexp_regexp ||= (
              Regexp.new([
                Regexp.quote("s(:iter, s(:call, nil, :"),
                "(proc|lambda)",
                Regexp.quote(", s(:arglist)), s(:lasgn, :#{code_match_args[:arg]}), s("),
              ].join)
            )
          end

          def frag_regexp
            @frag_regexp ||= (
              end_marker = {'do' => 'end', '{' => '\}'}[code_match_args[:start_marker]]
              /^(.*?\W#{end_marker})/m
            )
          end

          def code_regexp
            @code_regexp ||=
              /^(.*?(Otaku\.start.*?|lambda|proc|Proc\.new)\s*(do|\{)\s*\|(\w+)\|\s*)/m
          end

          def code_match_args
            @code_match_args ||= (
              args = source_code.match(code_regexp)
              {
                :ignore => args[1],
                :start_marker => args[3],
                :arg => args[4]
              }
            )
          end

          def source_code
            @source_code ||= (
              file, line = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+).*?>$/.match(@block.inspect)[1..2]
              @file = File.expand_path(file)
              @line = line.to_i
              File.readlines(@file)[@line.pred .. -1].join
            )
          end

          def replace_magic_vars(code)
            %w{__FILE__ __LINE__}.inject(code) do |code, var|
              code.gsub(var, "%|((#{var}))|")
            end
          end

          def revert_magic_vars(code)
            %w{__FILE__ __LINE__}.inject(code) do |code, var|
              code.gsub(%|"((#{var}))"|, var)
            end
          end

      end

  end
end
