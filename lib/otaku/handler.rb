module Otaku
  class Handler

    def initialize(context, handler)
      @context = __context_as_code__(context)
      @proc = __proc_as_code__(handler)
    end

    def [](data)
      eval(@context).instance_exec(data, &eval(@proc))
    end

    private

      def __context_as_code__(methods_hash)
        'Class.new{ %s }.new' %
          methods_hash.map do |method, val|
            "def #{method}; Encoder.decode(%|#{Encoder.encode(val).gsub('|','\|')}|); end"
          end.sort.join('; ')
      end

      def __proc_as_code__(block)
        MagicProc.new(block).to_code
      end

      class MagicProc

        RUBY_PARSER = RubyParser.new
        RUBY_2_RUBY = Ruby2Ruby.new

        def initialize(block)
          @block = block
        end

        def to_code
          code, remaining = code_fragments

          while frag = remaining[frag_regexp,1]
            begin
              sexp = RUBY_PARSER.parse(code += frag, File.expand_path(@file))
              return RUBY_2_RUBY.process(sexp) if sexp.inspect =~ sexp_regexp
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
            @file, line_no = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+).*?>$/.match(@block.inspect)[1..2]
            @line_no = line_no.to_i
            File.readlines(@file)[@line_no.pred .. -1].join
          )
        end

      end

  end
end
