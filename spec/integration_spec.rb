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

    should 'raise Otaku::DataProcessError w proc that has contextual reference yet has no specified context' do
      mark = '*'
      Otaku.start{|data| '%s %s %s' % [mark, data, mark] }
      lambda { Otaku.process('hello') }.should.raise(Otaku::DataProcessError).
        message.should.match(/#<NameError: undefined local variable or method `mark' for /)
    end

    should 'succeed w proc that has contextual reference & has context specified' do
      Otaku.start(:mark => '*') {|data| '%s %s %s' % [mark, data, mark] }
      Otaku.process('hello').should.equal('* hello *')
    end

  end

end