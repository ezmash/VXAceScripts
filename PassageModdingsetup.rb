#========================================================================
# Passage Modding (setup)
# Version 1.0 (2013.09.12)
#========================================================================
# Author: Shaz
#------------------------------------------------------------------------
# This script lets you override passage settings on individual tiles and
# ignore the tileset defaults.
# This is a DEVELOPMENT-ONLY script, and should be removed prior to 
# releasing the game.  On release, use the corresponding (runtime) script.
#------------------------------------------------------------------------
# Changelog:
# 2013.09.12  v1.0  Initial release
#------------------------------------------------------------------------
# To install:
# Install into Materials section in your project's script editor below
# all other scripts
#------------------------------------------------------------------------
# To use:
# Turn on the console prior to testing your game
# Switch into Passage Modding Mode (press P)
# Use the following keys to make changes to passages:
# - P: Toggle passage modding on/off
# - X: Make the tile under the mouse impassable
# - O: Make the tile under the mouse passable
# - Click mouse: Toggle the passability of the 4-dir icon clicked on
# - C: Toggle icon color for dark/light backgrounds
# - R: Reset passages to last-saved (for current map only)
# - M: Reset passages to map/tileset defaults (for current map only)
# - S: Save passage settings (for ALL maps)
# - H: Print these instructions to the console
# Use your arrow keys to move your character around and scroll the map
# REMEMBER TO SAVE YOUR WORK WHILE IN PASSAGE MODDING MODE!
#------------------------------------------------------------------------
# Compatibility:
# This script may have compatibility issues with other scripts that:
# - modify the Game_Map.check_passage method
# - modify player movement and collision
# - modify the map during runtime (such as tile swapping scripts)
#------------------------------------------------------------------------
# Terms:
# Free for commercial and non-commercial use (though this is a tool
# and should be removed prior to release)
#========================================================================

CheckKeyState = Win32API.new('user32', 'GetKeyState', 'i', 'i')
#============================================================================
# MOUSE SCRIPT
# by SephirothSpawn and Near Fantastica (used in setup script only)
#============================================================================
module PMMouse
  #--------------------------------------------------------------------------
  # * Mouse to Input Triggers
  #   key => Input::KeyCONSTANT (key: 0 - left, 1 - middle, 2 - right)
  #--------------------------------------------------------------------------
  Mouse_to_Input_Triggers = {0 => Input::C, 1 => Input::B, 2 => Input::A}
  #--------------------------------------------------------------------------
  # * API Declarations
  #--------------------------------------------------------------------------
  GAKS = Win32API.new('user32', 'GetAsyncKeyState', 'i', 'i')
  GSM = Win32API.new('user32', 'GetSystemMetrics', 'i', 'i')
  Cursor_Pos = Win32API.new('user32', 'GetCursorPos', 'p', 'i')
  Scr2cli = Win32API.new('user32', 'ScreenToClient', %w(l p), 'i')
  Client_rect = Win32API.new('user32', 'GetClientRect', %w(l p), 'i')
  Findwindow = Win32API.new('user32', 'FindWindowA', %w(p p), 'l')
  Readini = Win32API.new('kernel32', 'GetPrivateProfileStringA', %w(p p p p l p), 'l')
  ShowCursor = Win32API.new('user32', 'ShowCursor', 'i', 'l')
  #--------------------------------------------------------------------------
  # * Module Variables
  #--------------------------------------------------------------------------
  @triggers = [[0, 1], [0, 2], [0, 4]]
  @old_pos = 0
  @pos_i = 0
  #--------------------------------------------------------------------------
  # * Mouse Grid Position
  #--------------------------------------------------------------------------
  def self.grid
    return nil if pos.nil?
    mx, my = $game_map.tilemap_offset
    x = (pos[0] + mx) / 32
    y = (pos[1] + my) / 32
    return [x, y]
  end
  #--------------------------------------------------------------------------
  # * Mouse Position
  #--------------------------------------------------------------------------
  def self.position
    return @pos.nil? ? [0, 0] : @pos
  end
  #--------------------------------------------------------------------------
  # * Mouse Global Position
  #--------------------------------------------------------------------------
  def self.global_pos
    pos = [0, 0].pack('ll')
    return Cursor_Pos.call(pos) == 0 ? nil : pos.unpack('ll')
  end
  #--------------------------------------------------------------------------
  # * Screen to Client
  #--------------------------------------------------------------------------
  def self.screen_to_client(x=0, y=0)
    pos = [x, y].pack('ll')
    return Scr2cli.call(self.hwnd, pos) == 0 ? nil : pos.unpack('ll')
  end
  #--------------------------------------------------------------------------
  # * Mouse Position
  #--------------------------------------------------------------------------
  def self.pos
    gx, gy = global_pos
    x, y = screen_to_client(gx, gy)
    
    # Test boundaries
    begin
      if (x >= 0 && y >= 0 && x <= Graphics.width && y <= Graphics.height)
        return x, y
      else
        return -20, -20
      end
    rescue
      return 0, 0
    end
  end
  #--------------------------------------------------------------------------
  # * Update Mouse Position
  #--------------------------------------------------------------------------
  def self.update
    # Update Triggers
    for i in @triggers
      n = GAKS.call(i[1])
      if [0, 1].include?(n)
        i[0] = (i[0] > 0 ? i[0] * -1 : 0)
      else
        i[0] = (i[0] > 0 ? i[0] + 1 : 1)
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Trigger?
  #   id : 0:Left, 1:Right, 2:Center
  #--------------------------------------------------------------------------
  def self.trigger?(id = 0)
    if pos != [-20, -20]
      return @triggers[id][0] == 1
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Repeat?
  #   id : 0:Left, 1:Right, 2:Center
  #--------------------------------------------------------------------------
  def self.repeat?(id = 0)
    return @triggers[id][0] > 0 && @triggers[id][0] % 5 == 1 
  end
  #--------------------------------------------------------------------------
  # * Hwnd
  #--------------------------------------------------------------------------
  def self.hwnd
    if @hwnd.nil?
      title = "\0" * 256
      Readini.call('Game', 'Title', '', title, 255, '.\\Game.ini')
      title.delete!("\0")
      @hwnd = Findwindow.call('RGSS Player', title) 
    end
    return @hwnd
  end
  #--------------------------------------------------------------------------
  # * Client Size
  #--------------------------------------------------------------------------
  def self.client_size
    rect = [0, 0, 0, 0].pack('l4')
    Client_rect.call(self.hwnd, rect)
    return rect.unpack('l4')[2..3]
  end
end

class << Input
  #--------------------------------------------------------------------------
  # * Alias Listings
  #--------------------------------------------------------------------------
  alias :seph_pmmouse_input_update :update
  alias :seph_pmmouse_input_trigger? :trigger?
  alias :seph_pmmouse_input_repeat? :repeat?
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    PMMouse.update
    seph_pmmouse_input_update
  end
  #--------------------------------------------------------------------------
  # * Trigger? Test
  #--------------------------------------------------------------------------
  def trigger?(constant)
    return true if seph_pmmouse_input_trigger?(constant)
    unless PMMouse.pos.nil?
      if PMMouse::Mouse_to_Input_Triggers.has_value?(constant)
        return true if PMMouse.trigger?(PMMouse::Mouse_to_Input_Triggers.index(constant))
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Repeat? Test
  #--------------------------------------------------------------------------
  def repeat?(constant)
    return true if seph_pmmouse_input_repeat?(constant)
    unless PMMouse.pos.nil?
      if PMMouse::Mouse_to_Input_Triggers.has_value?(constant)
        return true if PMMouse.repeat?(PMMouse::Mouse_to_Input_Triggers.index(constant))
      end
    end
    return false
  end
end
  

module DataManager
  class << self
    alias shaz_passage_mod_setup_load_normal_database load_normal_database
  end
  
  def self.load_normal_database
    shaz_passage_mod_setup_load_normal_database
    if File.exists?("Data/Passages.rvdata2")
      $data_passages = load_data("Data/Passages.rvdata2")
    else
      $data_passages = {}
    end
  end
end

class Sprite_Passability < Sprite
  # Create sprite for map passability
  def initialize(viewport)
    super(viewport)
    @color = 0
    @passages = $data_passages.clone
    create_icons
    create_bitmap
    self.visible = false
    update
  end
  
  # Create icons for passable / not passable in each direction
  def create_icons
    @rect = Rect.new(0, 0, 32, 32)
    
    @box1 = Bitmap.new(32, 32)
    @box1.fill_rect(0, 0, 32, 32, Color.new(255, 127, 127, 160))
    @box1.clear_rect(1, 1, 30, 30)
    
    @box2 = Bitmap.new(32, 32)
    @box2.fill_rect(0, 0, 32, 32, Color.new(127, 63, 63, 160))
    @box2.clear_rect(1, 1, 30, 30)
    
    @pass2 = Bitmap.new(32, 32)
    @pass2.fill_rect(15, 20, 3, 9, passability_color)
    @pass2.fill_rect(14, 23, 5, 4, passability_color)
    @pass2.fill_rect(13, 23, 7, 3, passability_color)
    @pass2.set_pixel(12, 23, passability_color)
    @pass2.set_pixel(20, 23, passability_color)
    @pass2.set_pixel(16, 29, passability_color)
    
    @block2 = Bitmap.new(32, 32)
    @block2.fill_rect(15, 23, 3, 2, passability_color)
    @block2.set_pixel(16, 22, passability_color)
    @block2.set_pixel(16, 25, passability_color)
    
    @pass4 = Bitmap.new(32, 32)
    @pass4.fill_rect(3, 15, 9, 3, passability_color)
    @pass4.fill_rect(5, 14, 4, 5, passability_color)
    @pass4.fill_rect(6, 13, 3, 7, passability_color)
    @pass4.set_pixel(2, 16, passability_color)
    @pass4.set_pixel(8, 12, passability_color)
    @pass4.set_pixel(8, 20, passability_color)
    
    @block4 = Bitmap.new(32, 32)
    @block4.fill_rect(7, 15, 3, 2, passability_color)
    @block4.set_pixel(8, 14, passability_color)
    @block4.set_pixel(8, 17, passability_color)
    
    @pass6 = Bitmap.new(32, 32)
    @pass6.fill_rect(20, 15, 9, 3, passability_color)
    @pass6.fill_rect(23, 14, 4, 5, passability_color)
    @pass6.fill_rect(23, 13, 3, 7, passability_color)
    @pass6.set_pixel(23, 12, passability_color)
    @pass6.set_pixel(23, 20, passability_color)
    @pass6.set_pixel(29, 16, passability_color)
    
    @block6 = Bitmap.new(32, 32)
    @block6.fill_rect(23, 15, 3, 2, passability_color)
    @block6.set_pixel(24, 14, passability_color)
    @block6.set_pixel(24, 17, passability_color)
    
    @pass8 = Bitmap.new(32, 32)
    @pass8.fill_rect(15, 3, 3, 9, passability_color)
    @pass8.fill_rect(14, 5, 5, 4, passability_color)
    @pass8.fill_rect(13, 6, 7, 3, passability_color)
    @pass8.set_pixel(16, 2, passability_color)
    @pass8.set_pixel(12, 8, passability_color)
    @pass8.set_pixel(20, 8, passability_color)
    
    @block8 = Bitmap.new(32, 32)
    @block8.fill_rect(15, 7, 3, 2, passability_color)
    @block8.set_pixel(16, 6, passability_color)
    @block8.set_pixel(16, 9, passability_color)
  end
    
  def create_bitmap
    load_passages_from_map if !@passages.has_key?($game_map.map_id)
    # Build passability image for current map
    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new($game_map.width * 32, $game_map.height * 32)
    self.bitmap.font.size = 16
    for tx in 0 ... $game_map.width
      for ty in 0 ... $game_map.height
        draw_passages(tx, ty)
      end
    end
  end
  
  def draw_passages(tx, ty)
    self.bitmap.clear_rect(tx * 32, ty * 32, 32, 32)
    self.bitmap.blt(tx * 32, ty * 32, (tx % 2 + ty % 2 == 1) ? @box1 : @box2, @rect)
    self.bitmap.blt(tx * 32, ty * 32, ovr_passage(tx, ty, 2) ? @pass2 : @block2, @rect)
    self.bitmap.blt(tx * 32, ty * 32, ovr_passage(tx, ty, 4) ? @pass4 : @block4, @rect)
    self.bitmap.blt(tx * 32, ty * 32, ovr_passage(tx, ty, 6) ? @pass6 : @block6, @rect)
    self.bitmap.blt(tx * 32, ty * 32, ovr_passage(tx, ty, 8) ? @pass8 : @block8, @rect)
  end
  
  def ovr_passage(x, y, d)
    bit = (1 << (d / 2 - 1)) & 0x0f
    flag = @passages[$game_map.map_id][x,y]
    pass = flag & bit == 0
    return pass
  end
  
  def dispose
    self.bitmap.dispose if self.bitmap
  end
  
  def passability_color
    [Color.new(255, 255, 255, 160), Color.new(0, 0, 0, 160)][@color]
  end
  
  def refresh
    dispose
    create_bitmap
    update
  end
  
  def update
    super
    update_position
  end
  
  def update_position
    self.ox = $game_map.display_x * 32
    self.oy = $game_map.display_y * 32
  end
  
  def set_passage(passable)
    x, y = *PMMouse.grid
    @passages[$game_map.map_id][x,y] = passable ? 0x00 : 0x0f
    draw_passages(x, y)
  end
  
  def toggle_4dir_passage
    x, y = *PMMouse.grid
    mx, my = *PMMouse.pos
    mx += $game_map.tilemap_offset[0]
    my += $game_map.tilemap_offset[1]
    ox = mx % 32
    oy = my % 32
    dir = (ox - 16).abs > (oy - 16).abs ? (ox < 16 ? 4 : 6) : (oy < 16 ? 8 : 2)
    bit = (1 << (dir / 2 - 1)) & 0x0f
    @passages[$game_map.map_id][x,y] ^= (1 << (dir / 2 - 1))
    draw_passages(x, y)
  end
  
  def toggle_visibility
    self.visible = !self.visible
    if self.visible
      p 'Turning on Passability mode.  Remember to save your work.' 
    else
      p 'Turning off Passability mode.'
      p 'If you have made changes, remember to switch modes again and save your work.'
    end
  end
  
  def toggle_color
    @color = 1 - @color
    create_icons
    refresh
    p 'Setting icon color for ' + (@color == 0 ? 'dark' : 'light') + ' background'
  end
  
  def map_source
    load_passages_from_map
    refresh
  end
  
  def reload
    if $data_passages.has_key?($game_map.map_id)
      @passages[$game_map.map_id] = $data_passages[$game_map.map_id].clone
      p 'Loading last-saved passages for this map'
    else
      load_passages_from_map
      p 'Passages not saved for this map'
    end
    refresh
  end
  
  def load_passages_from_map
    p 'Loading default tileset passages for this map'
    @passages[$game_map.map_id] = Table.new($game_map.width, $game_map.height)
    for tx in 0 ... $game_map.width
      for ty in 0 ... $game_map.height
        flag = 0x00
        flag |= 1 if !$game_map.def_passable?(tx, ty, 2)
        flag |= 1 << 1 if !$game_map.def_passable?(tx, ty, 4)
        flag |= 1 << 2 if !$game_map.def_passable?(tx, ty, 6)
        flag |= 1 << 3 if !$game_map.def_passable?(tx, ty, 8)
        @passages[$game_map.map_id][tx,ty] = flag
      end
    end
  end
  
  def save_passages
    $data_passages = @passages.clone
    File.open("Data/Passages.rvdata2", "wb") do |file|
      Marshal.dump($data_passages, file)
    end
    p 'Passages for ALL maps saved'
  end
end

class Game_Map
  attr_accessor :tilemap_offset   
  attr_accessor :passage_modding
  
  alias shaz_passage_mod_game_map_initialize initialize
  alias shaz_passage_mod_update_events update_events
  
  def initialize
    shaz_passage_mod_game_map_initialize
    @tilemap_offset = [0, 0]
  end
  
  def def_check_passage(x, y, bit)
    all_tiles(x, y).each do |tile_id|
      flag = tileset.flags[tile_id]
      next if flag & 0x10 != 0            # [☆]: No effect on passage
      return true  if flag & bit == 0     # [○] : Passable
      return false if flag & bit == bit   # [×] : Impassable
    end
    return false                          # Impassable
  end
  
  def def_passable?(x, y, d)
    def_check_passage(x, y, (1 << (d / 2 - 1)) & 0x0f)
  end
  
  def update_events
    shaz_passage_mod_update_events if !@passage_modding
  end
end

class Spriteset_Map
  attr_accessor :passability_sprite
  alias shaz_passage_mod_create_viewports create_viewports
  alias shaz_passage_mod_create_tilemap create_tilemap
  alias shaz_passage_mod_update_tilemap update_tilemap
  alias shaz_passage_mod_dispose_tilemap dispose_tilemap
  alias shaz_passage_mod_dispose_viewports dispose_viewports
  
  def create_viewports
    shaz_passage_mod_create_viewports
    @viewport_passage = Viewport.new
    @viewport_passage.z = 150
  end
  
  def create_tilemap
    @passability_sprite = Sprite_Passability.new(@viewport_passage)
    shaz_passage_mod_create_tilemap
  end
  
  def update_tilemap
    shaz_passage_mod_update_tilemap
    @passability_sprite.update
  end
  
  def dispose_tilemap
    shaz_passage_mod_dispose_tilemap
    @passability_sprite.dispose
  end
  
  def dispose_viewports
    shaz_passage_mod_dispose_viewports
    @viewport_passage.dispose
  end
  
  def tilemap_offset
    [@tilemap.ox, @tilemap.oy]
  end
end 

class Scene_Map < Scene_Base
  alias shaz_passage_mod_start start
  alias shaz_passage_mod_update update
  alias shaz_passage_mod_post_transfer post_transfer
  alias shaz_passage_mod_update_scene update_scene
  
  KEYS = {'P' => [80, 0, :pass_p], # toggle passability modding on/off
          'X' => [88, 0, :pass_x], # set passability to X
          'O' => [79, 0, :pass_o], # set passability to O
          'C' => [67, 0, :pass_c], # toggle passability color light/dark
          'R' => [82, 0, :pass_r], # reset passability to pre-save
          'M' => [77, 0, :pass_m], # reset passability to map defaults
          'S' => [83, 0, :pass_s], # save passability overrides
          'H' => [72, 0, :pass_h]} # help

  def update
    if $TEST
      KEYS.each {|key, value|
        press = CheckKeyState.call(value[0])
        if [0,1].include?(press)
          if value[1] != press
            KEYS[key][1] = press
            method(value[2]).call
          end
        end
      }
    end
    mouse_click if PMMouse.trigger?(0) && !PMMouse.grid.nil?
    shaz_passage_mod_update
    $game_map.tilemap_offset = @spriteset.tilemap_offset
  end
  
  def update_scene
    shaz_passage_mod_update_scene if !$game_map.passage_modding
  end
  
  # Toggle passability override on/off
  def pass_p    
    @spriteset.passability_sprite.toggle_visibility
    $game_map.passage_modding = @spriteset.passability_sprite.visible
    if $game_map.passage_modding
      $game_player.through = true
    else
      $game_player.through = false
    end
  end
  
  # Set tile passability to X
  def pass_x    
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.set_passage(false)
  end
  
  # Set tile passability to O
  def pass_o    
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.set_passage(true)
  end
  
  # Process mouse click
  def mouse_click
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.toggle_4dir_passage
  end
  
  # Toggle color of passability icons
  def pass_c    
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.toggle_color
  end
  
  # Reset passability to last-saved
  def pass_r    
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.reload
  end
  
  # Reset passability to map defaults
  def pass_m    
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.map_source
  end
  
  # Save passability changes
  def pass_s
    return if !$game_map.passage_modding
    @spriteset.passability_sprite.save_passages
  end
  
  # Help (print instructions to console)
  def pass_h
    p 'Passing Modding'
    p '---------------'
    p 'P - toggle passage modding on/off'
    p 'X - set tile under mouse to impassable'
    p 'O - set tile under mouse to passable'
    p 'C - toggle color of passability icons'
    p 'R - reset passability map to last saved version'
    p 'M - reset passability map to tileset defaults'
    p 'S - save passage settings'
    p 'H - print these instructions'
    p ''
    p 'To change 4-dir passage settings, click on the'
    p 'icons with the mouse'
    p ''
    p 'Use your arrow keys to move your character'
    p 'and scroll the map'
    p ''
    p 'NOTE - normal event and keyboard functions are'
    p 'disabled during passage modding'
    p ''
    p 'REMEMBER TO SAVE YOUR WORK!'
    p ''
  end
  
  # rebuild passability image on new map
  def post_transfer
    @spriteset.passability_sprite.refresh
    shaz_passage_mod_post_transfer
  end
end

class Game_Player < Game_Character
  alias shaz_passage_mod_dash? dash?
  alias shaz_passage_mod_move_by_input move_by_input
  def dash?
    return true if $game_map.passage_modding
    shaz_passage_mod_dash?
  end
  
  def through=(value)
    @through = value
  end
  
  def move_by_input
    if $game_map.passage_modding
      return if !movable? || $game_map.interpreter.running?
      move_straight(Input.dir4) if Input.dir4 > 0
    else
      shaz_passage_mod_move_by_input
    end
  end
end

class Game_Event < Game_Character
  alias shaz_passage_mod_start start
  def start
    shaz_passage_mod_start if !$game_map.passage_modding
  end
end

# print some instructions
p 'Passing Modding'
p '---------------'
p 'P - toggle passage modding on/off'
p 'X - set tile under mouse to impassable'
p 'O - set tile under mouse to passable'
p 'C - toggle color of passability icons'
p 'R - reset passability map to last saved version'
p 'M - reset passability map to tileset defaults'
p 'S - save passage settings'
p 'H - print these instructions'
p ''
p 'To change 4-dir passage settings, click on the'
p 'icons with the mouse'
p ''
p 'Use your arrow keys to move your character'
p 'and scroll the map'
p ''
p 'NOTE - normal event and keyboard functions are'
p 'disabled during passage modding'
p ''
p 'REMEMBER TO SAVE YOUR WORK!'
p ''