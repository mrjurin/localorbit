require 'yaml'
require 'pry'
module LinkCustomers
  extend self
  def match_markets
    markets = load_markets

    stripe_custs = load_stripe_customers
    stripe_custs_by_bcid = index_stripe_custs(stripe_custs)

    matched_markets = []
    missed_markets = []

    markets.each do |_,market|
      bcid = market[:balanced_customer_id]
      if bcid and sc = stripe_custs_by_bcid[bcid]
        matched_markets << market.merge(stripe_customer_id: sc[:id])
      else
        missed_markets << market
      end
    end

    write_yaml "tools/stripe-migration/matched_markets.yml", matched_markets
    write_yaml "tools/stripe-migration/missed_markets.yml", missed_markets
  end

  def match_organizations
    orgs = load_organizations

    stripe_custs = load_stripe_customers
    stripe_custs_by_bcid = index_stripe_custs(stripe_custs)

    matched_orgs = []
    missed_orgs = []

    orgs.each do |_,org|
      bcid = org[:balanced_customer_id]
      if bcid and sc = stripe_custs_by_bcid[bcid]
        matched_orgs << org.merge(stripe_customer_id: sc[:id])
      else
        missed_orgs << org
      end
    end

    write_yaml "tools/stripe-migration/matched_organizations.yml", matched_orgs
    write_yaml "tools/stripe-migration/missed_organizations.yml", missed_orgs
  end

  def load_stripe_customers
    YAML.load_file("tools/stripe-migration/downloaded_stripe_customers.yml")
  end

  def load_markets
    YAML.load_file("#{lo_prod_dir}/markets.yml")
  end

  def load_organizations
    YAML.load_file("#{lo_prod_dir}/organizations.yml")
  end

  def index_markets(markets)
    idx = {}
    markets.each do |id,m|
      bcid = m[:balanced_customer_id]
      idx[bcid] = m if bcid
    end
    idx
  end

  def index_stripe_custs(stripe_custs)
    idx = {}
    stripe_custs.each do |sc|
      bcid = sc[:metadata][:"balanced.customer_id"]
      idx[bcid] = sc if bcid
    end
    idx
  end

  def lo_prod_dir
    dir = "tools/stripe-migration/lo-prod-ids"
  end

  def write_yaml(fname, data)
    File.write fname, YAML.dump(data)
    puts "Wrote #{fname}"
  end
end

# LinkCustomers.match_markets
LinkCustomers.match_organizations
