module Utils

  def archive_directory(dir, zip_file)

  end

  def duplicate_record(record,how_many,dir)
    
  end


  def generate_patient(number_of_entries)  	
    eruby = Erubis::EscapedEruby.new("fixtures/cat1_fragments/wrapper.xml") # TODO: cache these
    eruby.result(rendering_context.my_binding)
  end

  def my_binding
    binding
  end

end