#============================================================================
# Clone Events
# v1.0 by Shaz
#----------------------------------------------------------------------------
# This script allows you to clone events from one map to another.
# Customization options allow you to have all clone (source) events on the
# same map, or to specify which map should be used each time, and to
# use either event names or ids to indicate which event should be cloned
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
# Change the customization options in the module below to suit your 
# preferences -
# - to have all clone (source) events come from one map, set CLONE_MAP to the
#   map id containing all those events (this might be a map that the player
#   never actually sees.
# - to allow events from any map to be cloned, set CLONE_MAP to nil.
# - to use event names to indicate the source event, set USE_NAME to true.
#   This requires that clone (source) events on the original maps all have
#   unique names.
# - to use event ids to indicate the source event, set USE_NAME to false.
#
# Set up your events to be cloned.  If USE_NAME is set to true, ensure events
# that will be cloned all have unique names on the source map.
#
# To clone an event, on the game map, create a new event, and add a single
# comment to the event commands in one of the below formats:
# - if all clone sources are on the same map, use one of these:
#   <clone eventname>
#   <clone eventid>
# - if events from any map can be cloned, use one of these:
#   <clone mapid eventname>
#   <clone mapid eventid>
#
# Note - the event created will NOT get the same event id as the source.  It 
# will keep the event id of the 'dummy' event that has the <clone ...> comment.
# This means you can have several events on the same map that are all clones
# of the same original event.
# It also means you can use multiple event pages and self switches on your
# original event, and the self switches will refer to the correct map and
# event id, so they don't get mixed up.
#----------------------------------------------------------------------------
# Examples
#
# CLONE_MAP = nil
# USE_NAME = false
# <clone 18 23>
# will copy event 23 from map 18 to the current map
#
# CLONE_MAP = nil
# USE_NAME = true
# <clone 18 goldpouch>
# will copy the event whose name is goldpouch from map 18 to the current map
# 
# CLONE_MAP = 23
# USE_NAME = false
# <clone 6>
# will copy event 6 from map 23 to the current map
#
# CLONE_MAP = 23
# USE_NAME = true
# <clone goldpouch>
# will copy the event whose name is goldpouch from map 23 to the current map
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================

module CloneEvents
  # This is the map id that contains the source events to be cloned
  # set to nil if you want to be able to clone an event from ANY map
  CLONE_MAP = nil

  # Use event name, or event id?  If name, each event on the clone map
  # must have a unique name
  # true = use event name
  # false = use event id
  USE_NAME = false

  # Regular Expression Patterns
  PATT_MAP_NAME = /<clone\s+(\d+)\s+(\w+)>/i
  PATT_MAP_ID = /<clone\s+(\d+)\s+(\d+)>/i
  PATT_NAME = /<clone\s+(\w+)>/i
  PATT_ID = /<clone\s+(\d+)>/i
end



module DataManager
  class << self; 
    alias shaz_clone_events_load_normal_database load_normal_database 
  end
  
  def self.load_normal_database
    shaz_clone_events_load_normal_database
    load_cloned_events
  end
  
  def self.load_cloned_events
    $data_clones = {}
    if !CloneEvents::CLONE_MAP.nil?
      clone_map_events(CloneEvents::CLONE_MAP)
    end
  end
  
  def self.clone_map_events(map_id)
    $data_clones[map_id] = {}
    events = load_data(sprintf('Data/Map%03d.rvdata2', map_id)).events
    events.each do |i, event|
      name = CloneEvents::USE_NAME ? event.name.downcase : event.id.to_s
      $data_clones[map_id][name] = event.clone
    end
  end
end

class Game_Event < Game_Character
  @@clone_pattern = CloneEvents::CLONE_MAP.nil? ? 
    (CloneEvents::USE_NAME ? CloneEvents::PATT_MAP_NAME : CloneEvents::PATT_MAP_ID) : 
    (CloneEvents::USE_NAME ? CloneEvents::PATT_NAME : CloneEvents::PATT_ID)
    
  alias shaz_clone_events_initialize initialize
  def initialize(map_id, event)
    shaz_clone_events_initialize(map_id, event)
    check_clone
  end
  
  def check_clone
    if @event && @event.pages[0].list && @event.pages[0].list[0].code == 108
      @event.pages[0].list[0].parameters[0].gsub!(@@clone_pattern) do
        clone_map = CloneEvents::CLONE_MAP.nil? ? $1.to_i : CloneEvents::CLONE_MAP
        clone_name = (CloneEvents::CLONE_MAP.nil? ? $2.to_s : $1.to_s).downcase
        DataManager.clone_map_events(clone_map) if !$data_clones.has_key?(clone_map)
        @event.pages = Array.new($data_clones[clone_map][clone_name].pages.clone)
      end
    end
    @page = nil
    refresh
  end
end