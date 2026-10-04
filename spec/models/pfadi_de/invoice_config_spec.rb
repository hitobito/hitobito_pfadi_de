# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe InvoiceConfig do
  it "only offers no_ps as payment slip" do
    expect(InvoiceConfig.payment_slips).to eq(["no_ps"])
  end

  it "defaults new records to no payment slip" do
    expect(InvoiceConfig.new.payment_slip).to eq("no_ps")
  end

  it "offers no EBICS payment providers for Swiss banks" do
    expect(Settings.payment_providers.to_a).to eq([])
  end
end
