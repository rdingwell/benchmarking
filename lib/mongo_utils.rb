module MongoUtils

  def ensure_mongo(servers)

  end

  def start_mongo(servers)

  end

  def configure_mongo(servers)

  end

  def add_shard(servers,shard)

  end

  def remove_shard(servers,shard)

  end

  def remove_all_shards(servers)

  end

  def drop_collections(names)
    names.each do |name|
      Mongoid.default_session[name].drop
    end
  end

  def drop_collection(name)
    Mongoid.default_session[name].drop
  end
end