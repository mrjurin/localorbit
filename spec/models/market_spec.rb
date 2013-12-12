require 'spec_helper'

describe Market do
  describe 'validates' do
    let!(:original_market) { FactoryGirl.create(:market) }

    it 'name is unique' do
      market = FactoryGirl.build(:market)
      market.name = original_market.name

      expect(market).to_not be_valid
      expect(market).to have(1).error_on(:name)
    end

    it 'subdomain is unique' do
      market = FactoryGirl.build(:market)
      market.subdomain = original_market.subdomain

      expect(market).to_not be_valid
      expect(market).to have(1).error_on(:subdomain)
    end
  end

  describe 'before_save' do
    let(:market) { FactoryGirl.build(:market) }

    it 'remove @ from twitter slug' do
      market.twitter = '@collectiveidea'

      expect(market.save).to be_true
      market.reload
      expect(market.twitter).to eq('collectiveidea')
    end

    it "leaves the twitter slug alone if it doesn't start with @" do
      market.twitter = 'collectiveidea'

      expect(market.save).to be_true
      market.reload
      expect(market.twitter).to eq('collectiveidea')
    end
  end
end
