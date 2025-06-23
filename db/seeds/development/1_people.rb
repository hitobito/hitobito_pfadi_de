# frozen_string_literal: true

require Rails.root.join("db", "seeds", "support", "person_seeder")

class PfadiDePersonSeeder < PersonSeeder

  def amount(role_type)
    case role_type.name.demodulize
    when "Member" then 5
    else 1
    end
  end

end

puzzlers = [
  "Carlo Beltrame",
  "Olivier Brian",
  "Oliver Dietschi",
  "Thomas Ellenberger",
  "Daniel Illi",
  "Niklas Jäggi",
  "Andreas Maierhofer",
  "Nils Rauch",
  "Matthias Viehweger",
  "Pascal Zumkehr",
]

devs = {
  "Customer Name" => "customer@email.com"
}
puzzlers.each do |puz|
  devs[puz] = "#{puz.split.last.downcase.gsub("ü", "ue").gsub("ä", "ae")}@puzzle.ch"
end

seeder = PfadiDePersonSeeder.new

seeder.seed_all_roles

root = Group.root
devs.each do |name, email|
  seeder.seed_developer(name, email, root, Group::Root::Leader)
end
