#============================================================================
# Linked Variables
# v1.0 by Shaz
#----------------------------------------------------------------------------
# This script allows you to 'link' a variable with some other element in 
# your game, so whenever you refer to that variable (to SEE the value, not
# to SET it), it goes off to check the link and returns the appropriate
# value.
# It is the equivalent of doing a Control Variables to set a variable, prior
# to using that variable in a calculation, conditional branch, text box, etc.
# Note - the reference does not (currently) work in the other direction (nor
# do I plan to make it) - setting a linked variable to a value will not update
# whatever that link references.  (For example, if you add a link so variable
# 1 references $game_party.members.size, whenever you 'read' variable 1, it
# will return the current party size.  But if you 'change' variable 1, the 
# party size will not be affected.
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
# Add an element in the init_links method for the variable id, along with
# the script command to return the required value.
# See comments in that method (at the bottom of this script) for some 
# simple examples
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================

class Game_Variables
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias shaz_linked_variables_game_variables_initialize initialize
  def initialize
    shaz_linked_variables_game_variables_initialize
    init_links
  end
  #--------------------------------------------------------------------------
  # * Get Variable
  #--------------------------------------------------------------------------
  alias :data :[]
  def [](variable_id)
    init_links if @links.nil?
    !@links[variable_id].nil? ? eval(@links[variable_id]) : data(variable_id)
  end
  #--------------------------------------------------------------------------
  # * Initialize Links
  #--------------------------------------------------------------------------
  def init_links
    @links = []
    
=begin
    EXAMPLES
    This command tells variable 1 to return the current party size
    @links[1] = '$game_party.members.size'
    
    This command tells variable 2 to return the number of Item[2] in inventory
    @links[2] = '$game_party.item_number($data_items[2])'
    
    This command tells variable 3 to return the leader's HP Rate
    @links[3] = '$game_party.leader.hp_rate'
=end
  end
end