class Game_Map
  IGNORE_LAYER_PASSAGE_TERRAIN = 1
  #--------------------------------------------------------------------------
  # * Check Passage
  #     bit:  Inhibit passage check bit
  #--------------------------------------------------------------------------
  def check_passage(x, y, bit)
    all_tiles(x, y).each do |tile_id|
      flag = tileset.flags[tile_id]
      next if flag >> 12 == IGNORE_LAYER_PASSAGE_TERRAIN   # ignore passability on terrain tag
      next if flag & 0x10 != 0            # [☆]: No effect on passage
      return true  if flag & bit == 0     # [○] : Passable
      return false if flag & bit == bit   # [×] : Impassable
    end
    return false                          # Impassable
  end
end