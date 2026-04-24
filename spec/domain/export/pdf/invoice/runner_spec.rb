#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Pdf::Invoice do
  it "has customized runner" do
    expect(described_class.runner).to eq Export::Pdf::Invoice::RunnerWithProcessedSubjects
  end
end
