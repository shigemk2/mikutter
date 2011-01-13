# -*- coding: utf-8 -*-
#
# ruby config loader
#

# オブジェクトにデータ保存機能を付与する

require File.expand_path('utils')
miquire :core, 'environment'
miquire :core, 'serialthread'

require 'fileutils'
require 'thread'

module ConfigLoader
  SAVE_FILE = File.expand_path("#{Environment::CONFROOT}p_class_values.db")
  BACKUP_FILE = "#{SAVE_FILE}.bak"

  @@configloader_pstore = nil
  @@configloader_cache = Hash.new

  if(''.respond_to? :force_encoding)
    def to_utf8(a)
      unless(a.frozen?)
        if(a.is_a? Array)
          a.freeze
          return a.map &method(:to_utf8).freeze
        elsif(a.is_a? Hash)
          r = Hash.new
          a.freeze
          a.each{ |key, val|
            r[to_utf8(key)]= to_utf8(val) }
          return r.freeze
        elsif(a.respond_to? :force_encoding)
          return a.dup.force_encoding(Encoding::UTF_8).freeze rescue a
        end
      end
      a
    end
  else
    def to_utf8(a)
      a
    end
  end

  def at(key, ifnone=nil)
    ckey = configloader_key(key)
    return @@configloader_cache[ckey] if @@configloader_cache.has_key?(ckey)
    ConfigLoader.transaction(true){
      if ConfigLoader.pstore.root?(ckey) then
        to_utf8(ConfigLoader.pstore[ckey]).freeze
      elsif defined? yield then
        @@configloader_cache[ckey] = yield(key, ifnone).freeze
      else
        ifnone end } end

  def store(key, val)
    SerialThread.new{
      ConfigLoader.transaction{
        ConfigLoader.pstore[configloader_key(key)] = val } }
    if(val.frozen?)
      @@configloader_cache[configloader_key(key)] = val
    else
      @@configloader_cache[configloader_key(key)] = (val.clone.freeze rescue val) end end

  def store_before_at(key, val)
    result = self.at(key)
    self.store(key, val)
    return result || val
  end

  def configloader_key(key)
    "#{self.class.to_s}::#{key}".freeze end
  memoize :configloader_key

  def self.transaction(ro = false)
    self.pstore.transaction(ro){ |pstore|
      yield(pstore) } end

  def self.pstore
    if not(@@configloader_pstore) then
      FileUtils.mkdir_p(File.expand_path(File.dirname(SAVE_FILE)))
      @@configloader_pstore = HatsuneStore.new(File.expand_path(SAVE_FILE))
    end
    return @@configloader_pstore
  end

  def self.create(prefix)
    Class.new{
      include ConfigLoader
      define_method(:configloader_key){ |key|
        "#{prefix}::#{key}" } }.new end

  # データが壊れていないかを調べる
  def self.boot
    if(FileTest.exist?(SAVE_FILE))
    SerialThread.new{
      c = create("valid")
      if not(c.at(:validate)) and FileTest.exist?(BACKUP_FILE)
        FileUtils.copy(BACKUP_FILE, SAVE_FILE)
        @@configloader_pstore = nil
        warn "database was broken. restore by backup"
      else
        FileUtils.install(SAVE_FILE, BACKUP_FILE)
      end
      c.store(:validate, true)
    }
    end
  end

  boot

end
