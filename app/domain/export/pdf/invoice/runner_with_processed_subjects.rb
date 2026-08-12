#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module Export::Pdf::Invoice
  class RunnerWithProcessedSubjects < Runner
    private

    def sections
      super + [Export::Pdf::Invoice::ProcessedSubjectsSection]
    end
  end
end
