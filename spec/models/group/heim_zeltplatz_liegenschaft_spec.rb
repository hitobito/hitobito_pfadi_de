# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Group::HeimZeltplatzLiegenschaft do
  let(:parent) { groups(:baden_wuerttemberg) }

  it "stores the property attributes" do
    group = Fabricate(:"Group::HeimZeltplatzLiegenschaft", parent: parent,
      property_type: "building_with_campsite", property_owner: "municipality",
      property_facilities_sanitary: true, property_guests_interior: 40,
      rental_audience: "rdp", rental_public_listing: false)

    group.reload
    expect(group.property_type_label).to eq "Gebäude mit Zeltplatz"
    expect(group.property_owner_label).to eq "Kommune"
    expect(group.rental_audience_label).to eq "RDP"
    expect(group.property_guests_interior).to eq 40
  end

  it "rejects unknown enum values" do
    group = Fabricate.build(:"Group::HeimZeltplatzLiegenschaft", parent: parent,
      property_type: "castle", property_owner: "municipality")

    expect(group).not_to be_valid
    expect(group.errors).to include(:property_type)
  end

  it "requires property_type but not property_owner" do
    group = Fabricate.build(:"Group::HeimZeltplatzLiegenschaft", parent: parent)

    expect(group).not_to be_valid
    expect(group.errors).to include(:property_type)
    expect(group.errors).not_to include(:property_owner)
  end

  it "uses all property attributes" do
    expect(described_class.used_attributes).to include(:property_type, :rental_public_listing)
  end
end
