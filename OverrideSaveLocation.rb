#============================================================================
# Override Save Location
# v1.0 by Shaz
#----------------------------------------------------------------------------
# This script allows your game to put save files into the player's
# AppData folder, in a subfolder with the same name as the game.
#
# So, if your game is called Dragon Conquerer, save files will go into
# User/AppData/Roaming/Dragon Conquerer
# 
# This means several people can use the same PC under their own profiles,
# and have their own save files that can't be accidentally overwritten by
# others; players can uninstall, reinstall and overwrite your game without
# losing their save files; gets around file access issues if the game has
# been installed into a folder with additional Windows security.
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
# No steps necessary - it just works.
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================

module DataManager
  class << self
    alias shaz_custom_save_datamanager_init init
  end
  #--------------------------------------------------------------------------
  # * Initialize Module
  #--------------------------------------------------------------------------
  def self.init
    shaz_custom_save_datamanager_init
    create_app_paths
  end
  #--------------------------------------------------------------------------
  # * Create Custom Save Path
  #--------------------------------------------------------------------------
  def self.create_app_paths
    title = "\0" * 256
    readini = Win32API.new('kernel32', 'GetPrivateProfileStringA', %w(p p p p l p), 'l')
    readini.call('Game', 'Title', '', title, 255, '.\\Game.ini')
    title.delete!("\0")
    @savePath = ENV['APPDATA'] + "\\" + title
    Dir.mkdir(@savePath) if !File.exists?(@savePath)
    @savePath.gsub!(/\\/, '/')
  end
  #--------------------------------------------------------------------------
  # * Determine Existence of Save File
  #--------------------------------------------------------------------------
  def self.save_file_exists?
    !Dir.glob(@savePath + '/Save*.rvdata2').empty?
  end
  #--------------------------------------------------------------------------
  # * Create Filename
  #     index : File Index
  #--------------------------------------------------------------------------
  def self.make_filename(index)
    sprintf(@savePath + "/Save%02d.rvdata2", index + 1)
  end
end