#!/usr/bin/ruby
#--
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
#
# Check Web of Science Profile Organization, Person and Person_Organization
# spreadsheets. Eg. by verifying organization IDs are decendants of the root
# organization ID.
##############################################################################
# Add dirs to the library path
$: << File.expand_path("../lib", File.dirname(__FILE__))
$: << File.expand_path("../lib/libext", File.dirname(__FILE__))

require 'faster_csv'

##############################################################################
# A class to represent WoS Organization Units
##############################################################################
class OrgUnits

  ############################################################################
  def initialize(fname_csv)
    @fname_csv = fname_csv

    @root_id = nil
    @parent_ids = {}
    @descs = {}
    @path = {}		# A hash of arrays; each array is path-of-IDs to the root ID
    load_csv(@fname_csv)
  end

  ############################################################################
  def load_csv(fname, faster_csv_options={})
    puts "\n\nMethod: #{self.class}::#{__method__}"
    opts = {
      :col_sep => ',',
      :headers => false,
      :header_converters => :symbol,
      :quote_char => '"',
    }.merge!(faster_csv_options)

    root_count = 0
    count = 0
    FasterCSV.foreach(fname, opts) {|line|
      count += 1

      this_id = line[0]
      desc = line[1]
      parent_id = line[2]
      
      if this_id == parent_id
        root_count += 1
        @root_id = this_id
        STDERR.puts "INFO: ID #{this_id} -- Root record found on line #{count} -- #{line.inspect}"
      end
      STDERR.puts "ERROR: Line #{count} has nil ID. Must be a valid ID." if this_id.nil?
      STDERR.puts "ERROR: ID #{this_id} has nil parent ID on line #{count}. Must be a valid ID (or self-referencing for root)" if parent_id.nil?
      STDERR.puts "ERROR: ID #{this_id} is duplicated on line #{count} (earlier entry ignored)" if @parent_ids[this_id]

      STDERR.puts "WARNING: ID '#{this_id}' -- This ID contains leading or trailing white space" unless this_id.to_s == this_id.to_s.strip
      STDERR.puts "WARNING: ID #{this_id} -- Parent ID '#{parent_id}' contains leading or trailing white space" unless parent_id.to_s == parent_id.to_s.strip
      @parent_ids[this_id] = parent_id
      @descs[this_id] = desc
    }
    unless root_count == 1
      STDERR.puts "ERROR: Expected one root-record but found #{root_count}"
      exit 1
    end
  end

  ############################################################################
  def has_key?(key)
    @parent_ids.has_key?(key)
  end

  ############################################################################
  def to_s
    puts "\n\nMethod: #{self.class}::#{__method__}"
    sorted_lines = []
    @parent_ids.sort.each{|id, pid|
      sorted_lines << sprintf("%3s, %3s, %-20s, %s\n", id, pid, @descs[id], @path[id].inspect)
    }
    sorted_lines.join
  end

  ############################################################################
  def check_path_to_root
    puts "\n\nMethod: #{self.class}::#{__method__}"
    @parent_ids.sort.each{|id, pid|
      @path[id] = []

      if id == @root_id
        @path[id] << id
        @path[id] << "ok"

      else
        # FIXME: Detect loops
        prev_id = nil
        next_id = id
        while true
          @path[id] << next_id

          if @parent_ids[next_id].nil?
            @path[id] << "error-no-parent"
            STDERR.puts "ERROR: ID #{next_id} does not exist! (Child #{prev_id}; '#{@descs[prev_id]}')"
            break

          elsif next_id == @root_id
            @path[id] << "ok"
            break
          end

          prev_id = next_id
          next_id = @parent_ids[next_id]
        end
      end
    }
  end

end

##############################################################################
# A class to represent WoS Persons
##############################################################################
class Persons
  attr_reader :descs

  ############################################################################
  def initialize(fname_csv)
    @fname_csv = fname_csv
    @descs = {}
    load_csv(@fname_csv)
  end

  ############################################################################
  def load_csv(fname, faster_csv_options={})
    puts "\n\nMethod: #{self.class}::#{__method__}"
    opts = {
      :col_sep => ',',
      :headers => false,
      :header_converters => :symbol,
      :quote_char => '"',
    }.merge!(faster_csv_options)

    root_count = 0
    count = 0
    FasterCSV.foreach(fname, opts) {|line|
      count += 1

      this_id = line[0]
      desc = line[4]		# Must be a mandatory field (eg. email)
      
      STDERR.puts "ERROR: Line #{count} has nil ID. Must be a valid ID." if this_id.nil?
      STDERR.puts "ERROR: ID #{this_id} has nil field on line #{count}. Must not be empty (mandatory field)" if desc.nil?
      STDERR.puts "ERROR: ID #{this_id} is duplicated on line #{count} (earlier entry ignored)" if @descs[this_id]
      STDERR.puts "WARNING: ID '#{this_id}' -- This ID contains leading or trailing white space" unless this_id.to_s == this_id.to_s.strip
      @descs[this_id] = desc
    }
  end

  ############################################################################
  def has_key?(key)
    @descs.has_key?(key)
  end

  ############################################################################
  def to_s
    puts "\n\nMethod: #{self.class}::#{__method__}"
    sorted_lines = []
    @descs.sort.each{|id, desc|
      sorted_lines << sprintf("%s, %s\n", id, desc)
    }
    sorted_lines.join
  end

end

##############################################################################
# A class to represent WoS Person to Organization Unit (that is,
# many-to-many) relationships/links
##############################################################################
class Person2OrgUnit

  ############################################################################
  def initialize(fname_csv, org_units, persons)
    @fname_csv = fname_csv
    @org_units = org_units	# A populated OrgUnits object
    @persons = persons		# A populated Persons object

    @person_org_pairs = []	# Array of person-ou ID pairs (each being a 2 element array)
    @unique_person_ids = []		# A list of person IDs
    @unique_org_ids = []		# A list of organization IDs
    load_csv(@fname_csv)
  end

  ############################################################################
  def load_csv(fname, faster_csv_options={})
    puts "\n\nMethod: #{self.class}::#{__method__}"
    opts = {
      :col_sep => ',',
      :headers => false,
      :header_converters => :symbol,
      :quote_char => '"',
    }.merge!(faster_csv_options)

    count = 0
    FasterCSV.foreach(fname, opts) {|line|
      count += 1

      person_id = line[0]
      org_id = line[1]
      pair = [person_id, org_id]
      pair_str = pair.join(",")
      
      STDERR.puts "ERROR: Line #{count} -- Person-ID is nil. Must be a valid ID." if person_id.nil?
      STDERR.puts "ERROR: Line #{count} -- Person-ID #{person_id} has nil org-ID. Must be a valid ID." if org_id.nil?

      STDERR.puts "WARNING: Line #{count} -- Person-ID '#{person_id}' -- This ID contains leading or trailing white space" unless person_id.to_s == person_id.to_s.strip
      STDERR.puts "WARNING: Line #{count} -- Person-ID #{person_id} -- org-ID '#{org_id}' contains leading or trailing white space" unless org_id.to_s == org_id.to_s.strip
      STDERR.puts "WARNING: Line #{count} -- person-ID & org-unit-ID pair are a duplicate. #{pair_str}" if @person_org_pairs.any?{|p| p.join(",") == pair_str}
      @person_org_pairs << pair
      @unique_person_ids << person_id unless @unique_person_ids.include?(person_id)
      @unique_org_ids << org_id unless @unique_org_ids.include?(org_id)

      # Verify references into other object lists
      STDERR.puts "WARNING: Line #{count} -- Org-ID '#{org_id}' does not exist in the Org-CSV" if org_id && !@org_units.has_key?(org_id)
      STDERR.puts "WARNING: Line #{count} -- Person-ID '#{person_id}' does not exist in the Person-CSV" if person_id && !@persons.has_key?(person_id)
    }
    verify_all_people_in_org
  end

  ############################################################################
  def verify_all_people_in_org
    puts "\n\nMethod: #{self.class}::#{__method__}"
    # Assumes we've already verified that all Person2OrgUnit objects are
    # linked to an ID within OrgUnits. Hence we only need to verify that
    # each ID in Persons is linked to an OrgUnit at least once.
    @persons.descs.sort.each{|pkey, desc|
      STDERR.puts "WARNING: Person-ID #{pkey} not found in PersonOrganization CSV" unless @unique_person_ids.include?(pkey)
    }
  end

  ############################################################################
  def to_s
    puts "\n\nMethod: #{self.class}::#{__method__}"
    sorted_lines = []
    @person_org_pairs.each{|person_id, org_id|
      sorted_lines << sprintf("%s, %s\n", person_id, org_id)
    }
    sorted_lines.join
  end

end

##############################################################################
# Main
##############################################################################
fname_org_units = File.expand_path("../etc/org.csv", File.dirname(__FILE__))
org_units = OrgUnits.new(fname_org_units)
org_units.check_path_to_root
#puts org_units

fname_persons = File.expand_path("../etc/person.csv", File.dirname(__FILE__))
persons = Persons.new(fname_persons)
#puts persons

fname_person2ou = File.expand_path("../etc/person2org.csv", File.dirname(__FILE__))
person2ou = Person2OrgUnit.new(fname_person2ou, org_units, persons)
#puts person2ou

exit 0

