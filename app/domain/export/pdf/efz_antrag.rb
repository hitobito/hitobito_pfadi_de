# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module Export::Pdf
  class EfzAntrag
    attr_reader :person, :group, :document
    def initialize(group, person)
      @group = group
      @person = person
      @document = Export::Pdf::Document.new
    end

    def generate = document.pdf
  end
end
