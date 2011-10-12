require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe "shared index - complex scenarios", :type => :transactional do

  it "a contact is member of a contact list" do
    andreas = User.new('andreas', 'ronge', 'malmoe')
    petter  = User.new('petter', 'petterson', 'malmoe')

    petter.contact.users << andreas
    andreas.contact.users << petter

    finish_tx

#    puts "Andreas Address List:"
#    andreas.contacts.each {|x| puts "  #{x}"}
    andreas.contacts.should include(petter.contact)
    petter.contact.users.should include(andreas)

#    puts "Petter Address List:"
#    petter.contacts.each {|x| puts "  #{x}"}

    # Find everybody who knows someone living in malmoe ?
    result = [*Contact.find("city: malmoe")] #.first.should_not be_nil
    result.should_not be_empty
    result.should include(andreas.contact)
    result.should include(petter.contact)

    # Find all people andreas knows living in malmo
    Contact.find("user_id: #{andreas.user_id}").size.should == 1
    result = [*Contact.find("user_id: #{andreas.user_id} AND city: malmoe")]
    result.size.should == 1
    result.should include(petter.contact)
  end

  it "a user can have several contacts" do
    users = []
    users <<  User.new('andreas', 'ronge', 'malmoe')
    users <<  User.new('andreas', 'ronge', 'malmoe')
    users[0].contact.users << users[1]
    finish_tx

    found = [*Contact.find("user_id: #{users[1].neo_id}")]
    #found = [*Contact.find("user_id: #{users[0].neo_id} AND city: malmoe")]
    found.should_not be_empty
  end
end

describe "shared index - many to many", :type => :transactional do
  it "when a related node is created it should update the other nodes index" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    matrix = Movie.new :title => 'matrix'
    speed  = Movie.new :title => 'speed'
    keanu.acted_in << matrix << speed
    new_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('title: matrix', :type => :fulltext).first.should == keanu
    Actor.find('title: speed', :type => :fulltext).first.should == keanu
  end


  it "you can have both a shared index (via) and a none shared index on the same class" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    matrix = Movie.new :title => 'matrix'
    speed  = Movie.new :title => 'speed'
    keanu.acted_in << matrix << speed
    new_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('title: matrix', :type => :fulltext).first.should == keanu
    Actor.find('title: speed', :type => :fulltext).first.should == keanu

    Movie.find('title: matrix', :type => :fulltext).first.should == matrix
    Movie.find('title: speed', :type => :fulltext).first.should == speed
  end

  it "when a related node is connected it should update the other nodes index" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    matrix = Movie.new :title => 'matrix'
    speed  = Movie.new :title => 'speed'
    new_tx
    keanu.acted_in << matrix << speed
    finish_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('title: matrix', :type => :fulltext).first.should == keanu
    Actor.find('title: speed', :type => :fulltext).first.should == keanu
  end

  it "when all related node is deleted it should remove the indexes" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    matrix = Movie.new :title => 'matrix'
    speed  = Movie.new :title => 'speed'
    keanu.acted_in << matrix << speed
    new_tx

    # when
    keanu.acted_in_rels.each { |r| r.del }
    finish_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('title: matrix', :type => :fulltext).first.should be_nil
    Actor.find('title: speed', :type => :fulltext).first.should be_nil
  end

  it "when one related node is deleted it should remove the indexes" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    matrix = Movie.new :title => 'matrix'
    speed  = Movie.new :title => 'speed'
    keanu.acted_in << matrix << speed
    new_tx

    # when, delete the matrix relationship
    matrix.rels.first.del

    finish_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('title: matrix', :type => :fulltext).first.should be_nil
    Actor.find('title: speed', :type => :fulltext).first.should == keanu
  end

  it "when one related node is updated it should update the indexes" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    matrix = Movie.new :title => 'matrix'
    speed  = Movie.new :title => 'speed'
    keanu.acted_in << matrix << speed

    fishburne = Actor.new :name => 'Laurence Fishburne'
    fishburne.acted_in << matrix

    new_tx

    [*Actor.find('title: matrix', :type => :fulltext)].should include(keanu, fishburne)
    [*Actor.find('title: something', :type => :fulltext)].should be_empty

    # when, delete the matrix relationship
    matrix[:title] = 'something'

    finish_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('name: Laurence', :type => :fulltext).first.should == fishburne
    Actor.find('title: matrix', :type => :fulltext).should be_empty
    Actor.find('title: speed', :type => :fulltext).first.should == keanu
    [*Actor.find('title: something', :type => :fulltext)].should include(keanu, fishburne)
  end

  it "when a new related node is added the old should still be searchable" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    speed  = Movie.new :title => 'speed'
    keanu.acted_in << speed
    new_tx

    matrix = Movie.new :title => 'matrix'
    keanu.acted_in << matrix
    new_tx

    Actor.find('name: keanu', :type => :fulltext).first.should == keanu
    Actor.find('title: matrix', :type => :fulltext).first.should == keanu
    Actor.find('title: speed', :type => :fulltext).first.should == keanu
  end

  it "when a indexed node is deleted then all the related indexes should also be deleted" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    speed  = Movie.new :title => 'speed'
    matrix = Movie.new :title => 'matrix'

    new_tx
    keanu.acted_in << speed << matrix
    new_tx

    keanu.del
    finish_tx

    Actor.find('name: keanu', :type => :fulltext).first.should be_nil
    Actor.find('title: matrix', :type => :fulltext).first.should be_nil
    Actor.find('title: speed', :type => :fulltext).first.should be_nil
  end

  it "when indexed node is deleted then other node indexes should not be deleted" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    speed  = Movie.new :title => 'speed'
    matrix = Movie.new :title => 'matrix'

    fishburne = Actor.new :name => 'Laurence Fishburne'
    keanu.acted_in << speed << matrix
    fishburne.acted_in << matrix

    new_tx

    search = [*Actor.find('title: matrix', :type => :fulltext)]
    search.should include(keanu, fishburne)
    search.size.should == 2

    # when deleting keanu
    keanu.del
    finish_tx

    # then we still should find fishburne
    search = [*Actor.find('title: matrix', :type => :fulltext)]
    search.should include(fishburne)
    search.size.should == 1
  end

  it "when via indexed node is deleted it propogate to related nodes" do
    keanu  = Actor.new :name => 'Keanu Reeves'
    speed  = Movie.new :title => 'speed'
    matrix = Movie.new :title => 'matrix'

    fishburne = Actor.new :name => 'Laurence Fishburne'
    keanu.acted_in << speed << matrix
    fishburne.acted_in << matrix

    new_tx

    search = [*Actor.find('title: matrix', :type => :fulltext)]
    search.should include(keanu, fishburne)
    search.size.should == 2

    # when deleting speed
    speed.del
    finish_tx

    # then we still should find fishburne
    search = [*Actor.find('title: speed', :type => :fulltext)]
    search.should_not include(keanu)
    search.size.should == 0
  end

end

describe "shared index - one to one", :type => :transactional do

  it "simple test" do
    Person.new :name => 'pelle'
    new_tx

    p        = Person.find('name: pelle').first
    p.should_not be_nil
    p[:name] = 'sune'
    new_tx
    p        = Person.find('name: sune').first
    p.should_not be_nil

    p.del
    finish_tx

    p        = Person.find('name: sune').first
    p.should be_nil
  end

  it "when a related node is created it should update the other nodes index" do
    pelle            = Person.new :name => 'pelle'
    phone            = Phone.new :phone_number => '1234'
    pelle.home_phone = phone
    #phone.phone_number = '1234'

    finish_tx

    phone            = Person.find('name: pelle').first
    phone.should_not be_nil
    phone.should be_kind_of(Person)
    phone.name.should == 'pelle'

    phone1           = Person.find('name: "pelle" AND phone_number: "1234"').first
    phone1.should_not be_nil
    phone1.should be_kind_of(Person)
    phone1.neo_id.should == pelle.neo_id
  end


  it "when a new relationship is created between two nodes" do
    pelle            = Person.new :name => 'foobar2'
    phone            = Phone.new :phone_number=>'4243'

    new_tx

    # when
    pelle.home_phone = phone
    finish_tx

    # then
    Person.find('name: "foobar2" AND phone_number: "4243"').first.should_not be_nil
  end

  it "when a related node is deleted it should be deleted from other nodes index" do
    pelle            = Person.new :name => 'foobar0'
    phone            = Phone.new :phone_number=>'4242'
    pelle.home_phone = phone

    new_tx
    Person.find('name: "foobar0" AND phone_number: "4242"').first.should_not be_nil

    # when
    phone.del

    finish_tx

    Person.find('name: "foobar" AND phone_number: "4242"').first.should be_nil
  end

  it "when a related node relationship is deleted it should be deleted from other nodes index" do
    pelle            = Person.new :name => 'foobar1'
    phone            = Phone.new :phone_number=>'4243'

    pelle.home_phone = phone

    new_tx
    Person.find('phone_number: "4243"').first.should_not be_nil

    # when
    pelle.home_phone = nil
    pelle.home_phone.should be_nil

    finish_tx

    Person.find('name: "foobar1" AND phone_number: "4243"').first.should be_nil
  end

end
