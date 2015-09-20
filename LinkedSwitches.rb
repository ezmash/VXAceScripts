#============================================================================
# Linked Switches
# v1.0 by Shaz
#----------------------------------------------------------------------------
# This script allows you to 'link' a switch with some other element in
# your game, so whenever you refer to that switch (to SEE the value, not
# to SET it), it goes off to check the link and returns the appropriate
# value.
# It is the equivalent of doing a Control Switches to set a switch, prior
# to using that switch in a conditional branch.
# Note - the reference does not (currently) work in the other direction (nor
# do I plan to make it) - setting a linked switch to a value will not update
# whatever that link references.  (For example, if you add a link so switch
# 1 references $game_actors[1].battle_member?, whenever you 'read' switch 1, it
# will return true or false, depending on whether actor 1 is a battler.  
# But if you 'change' switch 1, this will not add or remove actor 1 from 
# your battlers
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
# Add an element in the init_links method for the switch id, along with
# the script command to return the required value (it must return a true/false
# value).
# See comments in that method (at the bottom of this script) for some
# simple examples
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================

class Game_Switches
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias shaz_linked_switches_game_switches_initialize initialize
  def initialize
    shaz_linked_switches_game_switches_initialize
    init_links
  end
  #--------------------------------------------------------------------------
  # * Get Switch
  #--------------------------------------------------------------------------
  alias :data :[]
  def [](switch_id)
    init_links if @links.nil?
    !@links[switch_id].nil? ? eval(@links[switch_id]) : data(switch_id)
  end
  #--------------------------------------------------------------------------
  # * Initialize Links
  #--------------------------------------------------------------------------
  def init_links
    @links = []

=begin
    EXAMPLES
    This command sets switch 1 to true when the party leader's hp is below 50%
    @links[1] = '$game_party.leader.hp_rate < 0.5'
    
    This command sets switch 2 to true when actor 1 is the leader
    @links[2] = '$game_party.leader.actor_id == 1'
    
    This command sets switch 3 to true when the player is on map 5, 8 or 10
    @links[3] = '[5, 8, 10].include?($game_map.map_id)'
=end
  end
end