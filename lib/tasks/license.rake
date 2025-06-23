# frozen_string_literal: true

namespace :app do
  namespace :license do
    task :config do # rubocop:disable Rails/RakeEnvironment
      @licenser = Licenser.new("hitobito_pfadi_de",
                               "Pfadfinder-Organisationen Deutschland",
                               "https://github.com/hitobito/hitobito_pfadi_de")
    end
  end
end
