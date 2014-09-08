require 'spec_helper'
require 'active_support/core_ext/kernel/reporting'

describe "sport_stats" do 

    it "should return the most improved player with regards to batting average with at bats > 200" do
        a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"))
        expect(a.batting_avg_most_imp).to eq([["carpean01", 233]])
    end

    it "should return nil if team was not found in csv" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test2.csv"))
      expect(a.batting_avg_most_imp).to eq(nil)
    end

    it "should return the most improved player with regards to batting average with at bats > 200 and with name" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"))
      b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
      expect(b.batting_avg_most_imp).to eq([["Andrew", "Carpenter", 233.0]])
    end

    it "should should include player name when passing HitterStats object into ConvertPlayerIdtoNames object" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"))
      b = SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
      expect(b.batting_avg_most_imp).to eq([["Andrew", "Carpenter", 233.0]])
    end

    it "should return nil if no player improved batting average (ie. everyones batting average became worse)" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test2.csv"),{:slugging_pct=>{:year=>2010,:team=>"PHI"}})
      b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
      expect(b.batting_avg_most_imp).to eq(nil)
    end

    it "should return error if non existant team is entered to calculate slugging percentage" do
         a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"))
         expect(a.slugging_percentage_list).to eq(nil)
    end

    it "should return slugging pct list with name" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:slugging_pct=>{:year=>2010,:team=>"PHI"}})
      b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
      expect(b.slugging_percentage_list).to eq({"PHI"=>[["Miguel", "Cairo", 0.624], ["Andrew", "Carpenter", 0.333], [nil, 0.095]]}) # A entry of nil, ex. [nil, 0.095] means no player name was found for the particular player id.
    end

    it "should calculate triple crown winner for the AL and NL leagues respectiviely" do
        a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:triple_crown=>{:year=>2012}})
        expect(a.triple_crown_winners).to eq({"AL"=>["cabremi01", "2012", "AL", "DET", "161", "622", "109", "205", "40", "0", "44", "139", "4", "1", 0.33], "NL"=>"(No winner)"})
    end

    it "should return a triple crown winner for 2012 for AL with name" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:triple_crown=>{:year=>2012}})
      b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
      expect(b.triple_crown_winners).to eq({"AL"=>["cabremi01", "1983", "Miguel", "Cabrera"], "NL"=>"(No winner)"})
    end

    it "should not return a triple crown winner for 2010 with name" do
      a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:triple_crown=>{:year=>2010}})
      b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
      expect(b.triple_crown_winners).to eq({"AL"=>"(No winner)", "NL"=>"(No winner)"})
    end
    
    it "should raise exception if non FileObj::CSVObj is passed in as a input to SportStats::HitterStats instance" do
        expect {
           SportStats::HitterStats.new("string input")
        }.to raise_error(RuntimeError, 'File Object input not of CSVObj type')
    end
    
    it "should print out most improved batting average list" do
        
        output = capture(:stdout) do
            a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:slugging_pct=>{:year=>2010,:team=>"PHI"}})
            b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
            a.batting_avg_list_out("./spec/test_assets/Master-small.csv")
        end
        expect(output).to include 'Andrew Carpenter 233.0'
        
    end
    
    it "should print out slugging pct list" do
        
        output = capture(:stdout) do
            a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:slugging_pct=>{:year=>2010,:team=>"PHI"}})
            b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
            a.slugging_pct_list_out("./spec/test_assets/Master-small.csv")
        end
        expect(output).to include 'Slugging Percentage in PHI'
    end
    
    it "should print out triple crown" do
        
        output = capture(:stdout) do
            a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:slugging_pct=>{:year=>2010,:team=>"PHI"}})
            b= SportStats::ConvertPlayerIdtoNames.new(a,"./spec/test_assets/Master-small.csv")
            a.triple_crown_out("./spec/test_assets/Master-small.csv")
        end
        expect(output).to include '["cabremi01", "1983", "Miguel", "Cabrera"]'
        
    end
    
    
    it "should raise exception if non stat class is passed into ConvertPlayerIdtoNames instance" do
        expect {
            SportStats::ConvertPlayerIdtoNames.new(3,"./spec/test_assets/Master-small.csv")
        }.to raise_error(RuntimeError, 'Input should be of Stats class type.')
    end
    
    it "should raise exception if non string file name is passed into ConvertPlayerIdtoNames instance" do
        expect {
            a = SportStats::HitterStats.new(FileObj::CSVObj.new("./spec/test_assets/hitter_file_test.csv"),{:slugging_pct=>{:year=>2010,:team=>"PHI"}})
            SportStats::ConvertPlayerIdtoNames.new(a,3)
        }.to raise_error(RuntimeError, 'File path input should be a string.')
    end
    
end
