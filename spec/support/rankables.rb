
shared_examples_for "rankable data" do
  let(:rankable) { described_class.new }
  
  it "has ranks" do
    expect(rankable.ranks).to be
  end
  
  describe "#rank!" do
    context "when rank value is between 0 and 1" do
      it "sets a named rank" do
        rankable.rank!(:test, 0)
        expect(rankable.ranks[:test]).to eq(0)
        rankable.rank!(:test, 1)
        expect(rankable.ranks[:test]).to eq(1)
        rankable.rank!(:test2, 0.5)
        expect(rankable.ranks[:test2]).to eq(0.5)
      end
    end
    
    context "otherwise" do
      it "raises an error" do
        expect{ rankable.rank!(:test, nil) }.to raise_error ArgumentError
        expect{ rankable.rank!(:test, -1) }.to raise_error ArgumentError
        expect{ rankable.rank!(:test, 1.1) }.to raise_error ArgumentError
        expect{ rankable.rank!(:test, true) }.to raise_error ArgumentError
        expect{ rankable.rank!(:test, 'awesome') }.to raise_error ArgumentError
      end
    end
    
    it "cannot be called while already inside"
  end
  
  describe "#total_rank" do
    it "returns the total rank" do
      rankable.rank!(:test1, 0.1)
      expect(rankable.total_rank).to eq(0.1)
      rankable.rank!(:test2, 0.4)
      expect(rankable.total_rank).to eq(0.5)
      rankable.rank!(:test1, 1)
      expect(rankable.total_rank).to eq(1.4)
    end
    
    it "returns 0 if no ranks" do
      expect(rankable.total_rank).to eq(0)
    end
    
    it "returns 0 if marked for deletion" do
      rankable.rank!(:test1, 1)
      rankable.delete!(:test1)
      rankable.total_rank.should == 0
    end
  end
  
  describe "#delete!" do
    it "marks this Rankable for deletion" do
      rankable.rank!(:test, 0)
      rankable.delete!(:test)
      # TODO: probably don't need to test the internal mechanism for how delete works
      expect(rankable.ranks[:test]).to be_nil
    end
    
    it "raises an error if no rank set yet" do
      expect{ rankable.delete!(:I_dont_exist) }.to raise_error ArgumentError
    end
  end
  
  describe "#delete?" do
    context "after #delete! is called" do
      before { rankable.rank!(:test, 0); rankable.delete!(:test) }
      it "returns true" do
        rankable.delete?.should be_true
      end
    end
    context "otherwise" do
      it "returns false" do
        rankable.delete?.should be_false
      end
    end
  end
end
