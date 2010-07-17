require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Otaku Service" do

  after do
    Otaku.stop
  end

  should 'successfully process when proc has no contextual reference' do
    Otaku.start{|data| '~ %s ~' % data }
    Otaku.process('hello').should.equal '~ hello ~'
  end

end
