namespace :benchmark do

	namespace :xml do
		desc "benchmark xml parsing"
		task :xml_parsing do 

		end
	end
  
  namespace :json do
  	desc "benchmark json parsing"
  	task :json_parsing do

  	end
  end

  namespace :archive do

    desc "reading from zip file" 
    task :read do

    end

    desc "import archives" 
    task :import do

    end
  end

end