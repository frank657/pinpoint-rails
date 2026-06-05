# Seeds a starter BJJ position/technique map into a workspace (docs/roadmap/phase-10).
# Users extend or ignore it; non-BJJ workspaces simply don't seed it.
module Bjj
  class SeedTaxonomy
    POSITIONS = [
      { name: "Standing", category: :standing, dominance: :neutral },
      { name: "Closed Guard", category: :guard, dominance: :neutral },
      { name: "Open Guard", category: :guard, dominance: :neutral },
      { name: "Half Guard", category: :guard, dominance: :neutral },
      { name: "Mount", category: :pin, dominance: :dominant },
      { name: "Side Control", category: :pin, dominance: :dominant },
      { name: "Back Control", category: :back, dominance: :dominant },
      { name: "Turtle", category: :turtle, dominance: :inferior },
      { name: "Leg Entanglement", category: :leg, dominance: :neutral }
    ].freeze

    TECHNIQUES = [
      { name: "Double Leg Takedown", from: "Standing", to: "Side Control", kind: :takedown },
      { name: "Scissor Sweep", from: "Closed Guard", to: "Mount", kind: :sweep },
      { name: "Triangle Choke", from: "Closed Guard", to: nil, kind: :submission },
      { name: "Knee Cut Pass", from: "Open Guard", to: "Side Control", kind: :pass },
      { name: "Hip Escape", from: "Mount", to: "Closed Guard", kind: :escape },
      { name: "Rear Naked Choke", from: "Back Control", to: nil, kind: :submission },
      { name: "Heel Hook", from: "Leg Entanglement", to: nil, kind: :submission }
    ].freeze

    def self.call(workspace)
      ActsAsTenant.with_tenant(workspace) do
        positions = POSITIONS.index_with { |attrs| find_position(attrs) }
                             .transform_keys { |attrs| attrs[:name] }
        TECHNIQUES.each do |t|
          Technique.find_or_create_by!(name: t[:name]) do |tech|
            tech.from_position = positions[t[:from]]
            tech.to_position = t[:to] && positions[t[:to]]
            tech.kind = t[:kind]
          end
        end
      end
    end

    def self.find_position(attrs)
      Position.find_or_create_by!(name: attrs[:name]) do |p|
        p.category = attrs[:category]
        p.dominance = attrs[:dominance]
      end
    end
  end
end
