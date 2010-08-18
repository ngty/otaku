require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Otaku Service" do

  describe '>> starting' do

    after do
      Otaku.stop
    end

    should 'raise Otaku::HandlerNotDefinedError when processing wo specified proc' do
      lambda { Otaku.start }.should.raise(Otaku::HandlerNotDefinedError)
    end

  end

  describe '>> processing' do

    after do
      Otaku.stop
    end

    should 'succeed w proc that has no contextual reference' do
      Otaku.start{|data| '~ %s ~' % data }
      Otaku.process('hello').should.equal '~ hello ~'
    end

    should 'succeed w proc that has contextual reference' do
      mark = '*'
      Otaku.start {|data| '%s %s %s' % [mark, data, mark] }
      Otaku.process('hello').should.equal('* hello *')
    end

    should 'reflect __FILE__ as captured when declaring proc' do
      Otaku.start {|data| __FILE__ }
      Otaku.process(:watever_data).should.equal(__FILE__)
    end

    should 'reflect __LINE__ as captured when declaring proc' do
      Otaku.start{|data| __LINE__ }
      Otaku.process(:watever_data).should.equal(__LINE__.pred)
    end

    should 'have $LOAD_PATH include Otaku.root' do
      Otaku.start do |data|
        @@_not_isolated_vars = :global
        $LOAD_PATH
      end
      Otaku.process(:watever_data).should.include(Otaku.root)
    end

    should 'have $LOAD_PATH include Otaku::Server#handler.root' do
      Otaku.start do |data|
        @@_not_isolated_vars = :global
        $LOAD_PATH
      end
      Otaku.process(:watever_data).should.include(Otaku::Server.handler.root)
    end

  end

end
