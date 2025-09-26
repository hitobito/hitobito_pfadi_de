# frozen_string_literal: true

#  Copyright (c) 2025, BDP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Group do
  let(:group) { groups(:adler) }

  subject { group }

  describe "iban" do
    before { group.iban = "DE00 0000 0000" }

    it "is validated" do
      expect(group).not_to be_valid
      expect(group.errors[:iban]).to include(I18n.t("errors.messages.invalid_iban"))
    end
  end
end
