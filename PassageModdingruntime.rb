#========================================================================
# Passage Modding (runtime)
# Version 1.03 (2014.07.19)
#========================================================================
# Author: Shaz
#------------------------------------------------------------------------
# This script uses previously saved passage settings in preference to
# the default map/tileset passabilities.
#------------------------------------------------------------------------
# Changelog:
# 2013.09.12  1.0  Initial release
# 2013.09.12  1.01 Tweaked Game_Map.check_passage processing
# 2013.12.21  1.02 Fixed issue with passages being read from compressed game
# 2014.07.19  1.03 Fixed issue with vehicles going anywhere on map
#------------------------------------------------------------------------
# To install:
# Install into Materials section in your project's script editor below
# all other scripts
#------------------------------------------------------------------------
# To use:
# This will only affect maps where you have previously modified the 
# passage settings using the corresponding setup script.
# If passage settings were modified for the current map, those will be
# used instead of the default map passages.  If passage settings for the
# current map have not been modified, the defaults will be used.
#------------------------------------------------------------------------
# Compatibility:
# This script may have compatibility issues with other scripts that:
# - modify the Game_Map.check_passage method
# - modify player movement and collision
# - modify the map during runtime (such as tile swapping scripts)
#------------------------------------------------------------------------
# Terms:
# Free for commercial and non-commercial use 
#------------------------------------------------------------------------
# Credit:
# - Shaz
#========================================================================

module DataManager
  class << self
    alias shaz_passage_mod_runtime_load_normal_database load_normal_database
  end
  
  def self.load_normal_database
    shaz_passage_mod_runtime_load_normal_database
    begin
      $data_passages = load_data("Data/Passages.rvdata2")
    rescue
      $data_passages = {}
    end
  end
end


class Game_Map
  alias shaz_passage_mod_runtime_check_passage_original check_passage
  def check_passage(x, y, bit)
    if $data_passages.has_key?(@map_id)
      return $data_passages[$game_map.map_id][x,y] & bit == 0
    else
      shaz_passage_mod_runtime_check_passage_original(x, y, bit)
    end
  end
  def boat_passable?(x, y)
    shaz_passage_mod_runtime_check_passage_original(x, y, 0x0200)
  end
  def ship_passable?(x, y)
    shaz_passage_mod_runtime_check_passage_original(x, y, 0x0400)
  end
  def airship_land_ok?(x, y)
    shaz_passage_mod_runtime_check_passage_original(x, y, 0x0800) && shaz_passage_mod_runtime_check_passage_original(x, y, 0x0f)
  end
end