require 'fastest-csv'
module FileObj
  class CSVObj
     attr_reader :raw_data, :header, :data, :header_index_hash
     def initialize(file_path)
        @raw_data = FastestCSV.parse(fix_corrupt_file(file_path))
        @header = @raw_data[0]
        @header_index_hash = Hash[@header.map.with_index.to_a] # Returns a hash with header names as the key and its index within the header row as the value.
        @data = @raw_data.drop(1) # Drops the header column.
     end
    private
     def fix_corrupt_file(file_path)
        File.read(file_path).tr("\n","").gsub("\r","\r\n")
     end
  end
end


