module Otaku
  class Handler

    RUBY_PARSER = RubyParser.new
    RUBY_2_RUBY = Ruby2Ruby.new

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
          end.join('; ')
      end

      def __proc_as_code__(block)
        code, remaining, frag_regexp, sexp_regexp = __proc_as_code_args__(block)

        while frag = remaining[frag_regexp,1]
          begin
            sexp = RUBY_PARSER.parse(code += frag)
            return RUBY_2_RUBY.process(sexp) if sexp.inspect =~ sexp_regexp
          rescue SyntaxError, Racc::ParseError, NoMethodError
            remaining.sub!(frag,'')
          end
        end
      end

      def __proc_as_code_args__(block)
        file, line_no = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+).*?>$/.match(block.inspect)[1..2]
        source_code = File.readlines(file)[line_no.to_i.pred .. -1].join

        code_regexp = /^(.*?(Otaku\.start.*?|lambda|proc|Proc\.new)\s*(do|\{)\s*\|(\w+)\|\s*)/m
        ignore, _, start_marker, arg = source_code.match(code_regexp)[1..4]
        end_marker = {'do' => 'end', '{' => '\}'}[start_marker]

        [
          code        = "proc #{start_marker} |#{arg}| ",
          remaining   = source_code.sub(ignore,''),
          frag_regexp = /^(.*?\W#{end_marker})/m,
          sexp_regexp = Regexp.new([
            Regexp.quote("s(:iter, s(:call, nil, :"),
            "(proc|lambda)",
            Regexp.quote(", s(:arglist)), s(:lasgn, :#{arg}), s("),
          ].join)
        ]
      end

  end
end
