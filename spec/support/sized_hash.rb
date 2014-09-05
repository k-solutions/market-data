shared_examples_for "SizedHash" do |the_class|
  MAX_SIZE = 10
  
  let( :sized_hash ) { described_class.new MAX_SIZE } 
  
  it "should have proper size" do
    sized_hash.max_size.should == MAX_SIZE
  end
  
  it "should respect size" do
    how_many = MAX_SIZE + 2
    sized_hash.should be_empty
    ( how_many + 1).times.each { |it| sized_hash[ it ] = it }
    sized_hash.size.should        == 10
    sized_hash[ how_many ].should == how_many
  end
  
  it "should respond to #{described_class::HASH_METHODS}" do
    the_hash = sized_hash
    described_class::HASH_METHODS.each { |hash_method| the_hash.should respond_to hash_method }
  end
end