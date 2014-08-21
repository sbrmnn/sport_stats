require "sport_stats/version"
require "fastest_csv"
require "file_obj"

module SportStats
    
    class ConvertPlayerIdtoNames
        attr_reader :stat
        
        def initialize(obj, player_name_file_path)
            
            if obj.is_a? Stats
              @stat = obj
            else
              raise "Input should be of Stats class type."
            end
            
            if player_name_file_path.class == String
               csv_file= FileObj::CSVObj.new(player_name_file_path)
               header_col = csv_file.header_index_hash
               player_names = csv_file.data.group_by{|e| e[header_col["playerID"]]}
            else
              raise "File path input should be a string."
            end
            
            convert_player_ids(player_names)
        end
    
        
        protected
        
        def child_stat_type
             @stat.class
        end
        
        private
        
        def convert_player_ids(player_names)
            if child_stat_type == HitterStats
                @stat.batting_avg_most_imp && @stat.batting_avg_most_imp.map!{|l| [player_names[l[0]],l[1]].flatten}
                @stat.slugging_percentage_list && @stat.slugging_percentage_list[@stat.slugging_percentage_list.keys.first].map!{|l| [ player_names[l[0]],l[1]].flatten}
                @stat.triple_crown_winners  &&  @stat.triple_crown_winners.keys.each do |key|
                @stat.triple_crown_winners[key]&& @stat.triple_crown_winners[key].class!= String && @stat.triple_crown_winners[key] = player_names[@stat.triple_crown_winners[key][0]].first
                end
             end
            
        end
        
    end

  class Stats
      
        def initialize(file_obj, options={})
            raise "File Object input not of CSVObj type"  unless file_obj.class == FileObj::CSVObj
            raise "Options input should be a hash"  unless options.class == Hash
        end
    end

    class BaseballStats < Stats
    end

    class HitterStats < BaseballStats
        attr_reader :batting_avg_most_imp, :slugging_percentage_list, :triple_crown_winners
        
        def initialize(file_obj, options={})
          super
          hitter_file?(file_obj)
          batting_avg_option = options[:batting_avg]
          slugging_pct_option = options[:slugging_pct]
          triple_crown_option = options[:triple_crown]
          
            if batting_avg_option && batting_avg_option[:start_year] && batting_avg_option[:end_year] && batting_avg_option[:min_at_bats]
                batting_avg_imp(file_obj, batting_avg_option[:start_year], batting_avg_option[:end_year], batting_avg_option[:min_at_bats])
            else
                batting_avg_imp(file_obj, 2009, 2010, 200)
            end

            if slugging_pct_option && slugging_pct_option[:year] && slugging_pct_option[:team]
                slugging_pct_by_team(file_obj,slugging_pct_option[:year],slugging_pct_option[:team])
            else
                slugging_pct_by_team(file_obj,2007,"OAK")
            end
            
            if triple_crown_option && triple_crown_option[:year]
                triple_crown(file_obj,triple_crown_option[:year])
            else
                triple_crown(file_obj, 2012)
            end

        end

        def batting_avg_list_out
                puts "Most improved batting average percentage wise:" << " " << "#{@batting_avg_most_imp}"
        end
        
        def slugging_pct_list_out
                puts "Slugging Percentage:" << " " << "#{@slugging_percentage_list}"
        end
        
        def triple_crown_out
                puts "Triple Crown winner by league:" << " " << "#{@triple_crown_winners}"
        end
        
        private
        
        def batting_avg_imp(csv_file,start_year, end_year, min_at_bats)
                header_col = csv_file.header_index_hash
                filtered_list = csv_file.data.group_by{|e| e[header_col["playerID"]] if (e[header_col["yearID"]].to_i==start_year || e[header_col["yearID"]].to_i == end_year)}.select{|k,v| v.group_by{|l| l[header_col["yearID"]]}.keys.size>1 } # (1)
                filtered_list.delete(nil) # (2)
                batting_avg_most_imp_list = filtered_list.map{|k,v| [k, batting_avg_imp_calc(v,min_at_bats,csv_file.header_index_hash)]}.delete_if{|l|l[1].nil?}.group_by{|obj| obj[1]}
            if batting_avg_most_imp_list.keys.max >= 0
                @batting_avg_most_imp = batting_avg_most_imp_list[batting_avg_most_imp_list.keys.max]
            else
                @batting_avg_most_imp = nil
            end
        end
        
        def slugging_pct_by_team(csv_file,year,teamID)
                header_col = csv_file.header_index_hash
                filtered_csv_by_team = csv_file.data.group_by{|e| e[header_col["teamID"]]}[teamID]
                
                if filtered_csv_by_team
                    filtered_csv_by_team_year = filtered_csv_by_team.select{|l| l[header_col["yearID"]].to_i==year}
                    @slugging_percentage_list= {"#{teamID}"=>filtered_csv_by_team_year.map{|l| [l[header_col["playerID"]], slugging_percentage_calc(l[header_col["H"]].to_i, l[header_col["2B"]].to_i, l[header_col["3B"]].to_i,l[header_col["HR"]].to_i, l[header_col["AB"]].to_i)] }.sort_by{|obj| obj[1]}.reverse!}
                else
                    @slugging_percentage_list = nil
                end
        end
        
        def triple_crown(csv_file, year)
            triple_crown_winners =Hash.new(nil)
            ["AL", "NL"].each do |l|
                triple_crown_winners[l]=triple_crown_calc(csv_file,l,year)
            end
            @triple_crown_winners = triple_crown_winners
        end
        
        def batting_avg_imp_calc(player_array, min_at_bats, header_index={})
                batting_player_array_hash = player_array.group_by{|e| e[header_index["yearID"]]} # (3)
                batting_h_ab_hash = Hash.new({:h=>0,:ab=>0}) # (4)
            
                batting_player_array_hash.each do |key, array| # Iterates through the batting_player_array hash to sum up the total at bats and hits for each year and stores the info in the batting_h_ab_hash with the key corresponding to the year and the value corresponding to a hash consisiting of the total hits and at_bats for the year.
                    for i in (0..array.size-1)
                    batting_h_ab_hash.store(key, {:h=>batting_h_ab_hash[key][:h]+array[i][header_index["H"]].to_i, :ab=>batting_h_ab_hash[key][:ab]+array[i][header_index["AB"]].to_i })
                    end
                end
            
                keys = batting_h_ab_hash.keys.sort # Returns batting_h_ab_hash keys with an array.size of 2 in ascending order. Ex. ["2009", "2010"]
                start_year = keys.first
                end_year = keys.last
                return nil if (batting_h_ab_hash[start_year][:ab] < min_at_bats || batting_h_ab_hash[end_year][:ab] < min_at_bats) # Makes sure at_bats is greater or equal to the min_at_bats for the start and end year, otherwise the record will be discarded.
                hits_start_yr = batting_h_ab_hash[start_year][:h]
                hits_end_yr = batting_h_ab_hash[end_year][:h]
                ab_start_yr = batting_h_ab_hash[start_year][:ab]
                ab_end_yr = batting_h_ab_hash[end_year][:ab]
                batting_avg_start_yr = batting_avg_calc(hits_start_yr,ab_start_yr)
                batting_avg_end_yr = batting_avg_calc(hits_end_yr,ab_end_yr)
                return ((batting_avg_end_yr -  batting_avg_start_yr).fdiv((batting_avg_start_yr))*100).round(2) # Calculates the improvement of batting average as a percentage.
        end
        
        def slugging_percentage_calc(hits,doubles,triples,home_runs, at_bats)
                at_bats = at_bats ? at_bats : 0
                
                if at_bats>=1
                    (((hits-doubles-triples-home_runs) + (2*doubles) + (3*triples) +(4*home_runs)).fdiv(at_bats)).round(3)
                else
                    0
                end
        end
        
        def batting_avg_calc(hits,at_bats)
                hits.fdiv(at_bats).round(3)
        end
        
        def triple_crown_calc(csv_file,league,year)
                header_col = csv_file.header_index_hash
                filtered_data = csv_file.data.select{|l| l[1].to_i == year && l[2]==league && (l[header_col["AB"]] ? l[header_col["AB"]].to_i : 0) > 400}.map{|l|[l,batting_avg_calc(l[header_col["H"]].to_i, l[header_col["AB"]].to_i)].flatten!}
                home_runs = filtered_data.group_by{|l|l[header_col["HR"]].to_i}
                rbi = filtered_data.group_by{|l|l[header_col["RBI"]].to_i}
                batting_avg = filtered_data.group_by{|l| l[14]}
            
                triple_crown_winner= batting_avg[batting_avg.keys.max] & rbi[rbi.keys.max] & home_runs[home_runs.keys.max]
    
                if triple_crown_winner
                    triple_crown_winner.first
                else
                    "(No winner)"
                end
                
        end
        
        def hitter_file?(file_obj)
                hitter_file_columns = ["playerID", "yearID", "league", "teamID", "G", "AB", "R", "H", "2B", "3B", "HR", "RBI", "SB", "CS"]
                column_names = file_obj.header
                hitter_file_columns == column_names & hitter_file_columns # Checks if all columns that are supposed to be in the hitter file are include in the csv.
        end
    end
    
    class PitcherStats < BaseballStats
    end
    
end

#(1) Filters the csv data to show records that fall either in the min or max year and returns an hash with the player name as the key and the associated records for the name as the value.

#(2) Records that fall outside the min and max year are stored in the key value of nil, hence we need to delete the nil key to make sure the key value pair isn't iterated over.

#(3) Takes the player array input and creates a hash with the year as the key and the player arrays corresponding to the year as the value. Ex. {"2010"=>[["hinsker01", "2010", "NL", "ATL", "131", "281", "38", "72", "21", "1", "11", "51", "0", "0"]], "2009"=>[["hinsker01", "2009", "NL", "PIT", "54", "106", "18", "27", "9", "0", "1", "11", "0", "0"], ["hinsker01", "2009", "AL", "NYA", "39", "84", "13", "19", "3", "0", "7", "14", "1", "0"]]}

#(4)
