# Seeds the BJJ Position taxonomy (Axis 2 — docs/decisions/0004) into a workspace.
#
# Positions are tenant-scoped (acts_as_tenant :workspace) and form a tree via `parent`.
# This task is idempotent: positions are matched by (workspace, name), so re-running it
# updates category/dominance/parent rather than creating duplicates.
#
#   bin/rails positions:seed                  # seed every workspace
#   bin/rails positions:seed[my-workspace]    # seed one workspace (id or friendly_id slug)
#
namespace :positions do
  # [ name, category, dominance, parent_name_or_nil ]
  # `dominance` is from the reference player's perspective (the one studying the position).
  TAXONOMY = [
    # --- Standing ---------------------------------------------------------
    [ "Standing",                :standing, :neutral,   nil ],
    [ "Clinch",                  :standing, :neutral,   "Standing" ],
    [ "Front Headlock",          :standing, :dominant,  "Standing" ],

    # --- Guard (bottom, neutral) -----------------------------------------
    [ "Guard",                   :guard,    :neutral,   nil ],
    [ "Closed Guard",            :guard,    :neutral,   "Guard" ],
    [ "High Guard",              :guard,    :neutral,   "Closed Guard" ],
    [ "Rubber Guard",            :guard,    :neutral,   "Closed Guard" ],
    [ "Open Guard",              :guard,    :neutral,   "Guard" ],
    [ "Spider Guard",            :guard,    :neutral,   "Open Guard" ],
    [ "Lasso Guard",             :guard,    :neutral,   "Open Guard" ],
    [ "De La Riva",              :guard,    :neutral,   "Open Guard" ],
    [ "Reverse De La Riva",      :guard,    :neutral,   "Open Guard" ],
    [ "X Guard",                 :guard,    :neutral,   "Open Guard" ],
    [ "Single Leg X (Ashi)",     :guard,    :neutral,   "Open Guard" ],
    [ "Butterfly Guard",         :guard,    :neutral,   "Open Guard" ],
    [ "Collar Sleeve",           :guard,    :neutral,   "Open Guard" ],
    [ "Half Guard",              :guard,    :neutral,   "Guard" ],
    [ "Knee Shield (Z Guard)",   :guard,    :neutral,   "Half Guard" ],
    [ "Deep Half Guard",         :guard,    :neutral,   "Half Guard" ],
    [ "Lockdown",                :guard,    :neutral,   "Half Guard" ],

    # --- Pins (top, dominant) --------------------------------------------
    [ "Mount",                   :pin,      :dominant,  nil ],
    [ "Low Mount",               :pin,      :dominant,  "Mount" ],
    [ "High Mount",              :pin,      :dominant,  "Mount" ],
    [ "S-Mount",                 :pin,      :dominant,  "Mount" ],
    [ "Technical Mount",         :pin,      :dominant,  "Mount" ],
    [ "Side Control",            :pin,      :dominant,  nil ],
    [ "Scarf Hold (Kesa Gatame)", :pin,      :dominant,  "Side Control" ],
    [ "North-South",             :pin,      :dominant,  "Side Control" ],
    [ "Knee on Belly",           :pin,      :dominant,  "Side Control" ],

    # --- Back (dominant) -------------------------------------------------
    [ "Back Control",            :back,     :dominant,  nil ],
    [ "Body Triangle",           :back,     :dominant,  "Back Control" ],

    # --- Leg entanglements (neutral) -------------------------------------
    [ "Ashi Garami",             :leg,      :neutral,   nil ],
    [ "50/50",                   :leg,      :neutral,   "Ashi Garami" ],
    [ "Outside Ashi",            :leg,      :neutral,   "Ashi Garami" ],
    [ "Inside Sankaku (Saddle)", :leg,      :neutral,   "Ashi Garami" ],

    # --- Turtle (bottom, inferior) ---------------------------------------
    [ "Turtle",                  :turtle,   :inferior,  nil ]
  ].freeze

  desc "Seed the BJJ position taxonomy into a workspace (arg: id or slug; default: all workspaces)"
  task :seed, [ :workspace ] => :environment do |_t, args|
    workspaces =
      if args[:workspace].present?
        [ Workspace.friendly.find(args[:workspace]) ]
      else
        Workspace.all.to_a
      end

    abort "No workspaces found — create a workspace first." if workspaces.empty?

    workspaces.each do |workspace|
      ActsAsTenant.with_tenant(workspace) do
        by_name = {}

        # Two passes so a parent always exists before its children reference it.
        # Match case-insensitively to respect the model's uniqueness rule and avoid
        # colliding with a differently-cased existing name (e.g. "Side control").
        TAXONOMY.each do |name, category, dominance, _parent|
          position = Position.where("LOWER(name) = ?", name.downcase).first_or_initialize
          position.name = name if position.new_record?
          position.category = category
          position.dominance = dominance
          position.save!
          by_name[name] = position
        end

        TAXONOMY.each do |name, _category, _dominance, parent_name|
          next if parent_name.nil?

          by_name[name].update!(parent: by_name.fetch(parent_name))
        end

        puts "#{workspace.name}: seeded #{TAXONOMY.size} positions (#{Position.count} total)."
      end
    end
  end
end
