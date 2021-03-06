require "spec_helper"

describe DeliveryDecorator do
  let(:delivery_schedule) { create(:delivery_schedule) }
  let(:current_org) { create(:organization, :single_location, markets: [delivery_schedule.market]) }
  let(:draper_context) { {context: {current_organization: current_org}} }

  subject { create(:delivery, delivery_schedule: delivery_schedule).decorate }

  describe "#type" do
    context "when type is a delivery" do
      it "displays as a delivery" do
        expect(subject.type).to eq("Delivery:")
      end
    end

    context "when type is a pickup" do
      let(:delivery_schedule) { create(:delivery_schedule, :buyer_pickup) }

      it "displays as a pickup" do
        expect(subject.type).to eq("Pick up:")
      end
    end
  end

  describe "#display_date" do
    subject { create(:delivery, deliver_on: Time.parse("2014-05-15 06:00:00 EDT")).decorate }

    it "displays the date of the upcoming delivery" do
      expect(subject.display_date).to eq("Thursday May 15, 2014")
    end
  end

  describe "#buyer_display_date" do
    subject { delivery.decorate }
    let(:delivery) { create(:delivery, 
                     deliver_on: Time.parse("2014-05-15 06:00:00 EDT"),
                     buyer_deliver_on: Time.parse("2014-07-21 09:15:00 EDT")) }

    it "displays the date of the upcoming delivery" do
      expect(subject.buyer_display_date).to eq("Monday July 21, 2014")
    end

    it "falls back to deliver_on if buyer_deliver_on is null" do
      delivery.buyer_deliver_on = nil
      expect(subject.buyer_display_date).to eq("Thursday May 15, 2014")
    end

    it "falls back to nil if both dates are null" do
      delivery.deliver_on = nil
      delivery.buyer_deliver_on = nil
      expect(subject.buyer_display_date).to be_nil
    end
  end

  describe "#seller_time_range and #fulfillment_time_range" do
    it "formats the seller delivery start/end times in human-readable format" do
      expect(subject.seller_time_range).to match(/between 7:00AM.+11:00AM/)
      expect(subject.fulfillment_time_range).to match(/between 7:00AM.+11:00AM/)
      delivery_schedule.seller_delivery_start = "4:15 PM"
      delivery_schedule.seller_delivery_end = "10:47 PM"
      expect(subject.seller_time_range).to match(/between 4:15PM.+10:47PM/)
      expect(subject.fulfillment_time_range).to match(/between 4:15PM.+10:47PM/)
    end
  end

  describe "#display_display_locations" do
    subject { create(:delivery, delivery_schedule: delivery_schedule).decorate(draper_context) }

    context "delivery is pickup" do
      let(:delivery_schedule) { create(:delivery_schedule, :buyer_pickup) }

      it "should return the address of the pickup location" do
        expect(subject.display_locations).not_to be_nil
        expect(subject.display_locations.count).to eql(1)
        expect(subject.display_locations.first).to eql(delivery_schedule.buyer_pickup_location)
      end
    end

    context "delivery is dropoff" do
      let!(:delivery_schedule) { create(:delivery_schedule) }

      it "should return the address of the buyers selected organization" do
        expect(subject.display_locations).not_to be_nil
        expect(subject.display_locations.count).to eql(1)
        expect(subject.display_locations.first).to eql(current_org.shipping_location)
      end

      context "and the selected organziation has multiple locations" do
        let!(:current_org) { create(:organization, :multiple_locations, markets: [delivery_schedule.market]) }

        it "returns a list of display_locations" do
          deleted = create(:location, organization: current_org, deleted_at: 1.minute.ago)

          expect(subject.display_locations.count).to eql(2)
          expect(subject.display_locations).to include(*current_org.locations.visible)
          expect(subject.display_locations).to_not include(deleted)
        end
      end
    end
  end
end
