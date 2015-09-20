#============================================================================
# State Commands
# v1.1 by Shaz
#----------------------------------------------------------------------------
# This script will let you run commands when a state is added or removed
# from a battler.
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
# To execute a command when a state is added, add the following line to the
# state's notes:
#    onadd: command
#
# To execute a command when a state is removed, add the following line to the
# state's notes:
#    onremove: command
#
# command is a RGSS script command that will be eval'd, so it may consist of
# any valid script command.  It may extend over more than one line, and may 
# consist of several commands separated by semi-colons, but it must NOT be
# broken by pressing the Enter key (just keep typing and let the editor put
# in its own line breaks by default).
#
# Examples:
# - this will just print a line of text to the console when the state is added
#   onadd: p 'state added'
#
# - this will print a line of text to the console AND reserve a common event
#   to be run on the map when the state is removed - note it's done over
#   two commands/lines (the second line will automatically wrap to 2 lines)
#   onremove: p 'state removed'
#   onremove: $game_temp.reserve_common_event(1)
#
# - this will run one of two commands based on the battler's current hp when 
#   a state is added (enter key is not used here to go to a second line)
#   onadd: if hp_rate < 0.5; p 'low hp - need topup'; 
#   else; p 'hp good'; end;
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Clear State Information
  #--------------------------------------------------------------------------
  alias shaz_state_commands_clear_states clear_states
  def clear_states
    @states.each {|state_id| state_remove_command(state_id) } if @states
    shaz_state_commands_clear_states
  end
  #--------------------------------------------------------------------------
  # * Add New State
  #--------------------------------------------------------------------------
  alias shaz_state_commands_add_new_state add_new_state
  def add_new_state(state_id)
    shaz_state_commands_add_new_state(state_id)
    state_add_command(state_id) if !state?(state_id)
  end
  #--------------------------------------------------------------------------
  # * Erase State
  #--------------------------------------------------------------------------
  def erase_state(state_id)
    state_remove_command(state_id) if state?(state_id)
    super
  end
  #--------------------------------------------------------------------------
  # * State Add Commands
  #--------------------------------------------------------------------------
  def state_add_command(state_id)
    $data_states[state_id].note.split(/[\r\n]/).each do |line|
      case line
      when /onadd:\s*(.*)/i
        eval($1)
      end
    end
  end
  #--------------------------------------------------------------------------
  # * State Remove Commands
  #--------------------------------------------------------------------------
  def state_remove_command(state_id)
    $data_states[state_id].note.split(/[\r\n]/).each do |line|
      case line
      when /onremove:\s*(.*)/i
        eval($1)
      end
    end
  end
end