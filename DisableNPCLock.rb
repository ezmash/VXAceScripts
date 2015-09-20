#============================================================================
# Disable NPC Lock
# v1.0 by Shaz
#----------------------------------------------------------------------------
# This is a simple script to allow NPC events to continue with their move
# route while you are interacting with them (they will not stop their 
# movement and turn to the player)
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
# Add the text <nolock> in a comment anywhere on your event's page
# (the closer to the top, the better)
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================

class Game_Event
  alias shaz_nolock_clear_page_settings clear_page_settings
  alias shaz_nolock_setup_page_settings setup_page_settings
  alias shaz_nolock_lock                lock
  
  #--------------------------------------------------------------------------
  # * Clear Event Page Settings
  #--------------------------------------------------------------------------
  def clear_page_settings
    shaz_nolock_clear_page_settings
    @nolock = false
  end
  #--------------------------------------------------------------------------
  # * Set Up Event Page Settings
  #--------------------------------------------------------------------------
  def setup_page_settings
    shaz_nolock_setup_page_settings
    # look for collision in first block of comments
    list_index = 0
    while list_index < @list.size && [108,408].include?(@list[list_index].code)
      if @list[list_index].parameters[0] =~ /<nolock>/i
        @nolock = true
        break
      end
      list_index += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Lock (Processing in Which Executing Events Stop)
  #--------------------------------------------------------------------------
  def lock
    shaz_nolock_lock if !@nolock
  end
end