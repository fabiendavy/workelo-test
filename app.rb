require 'json'
require 'date'
require 'pry'

def find_meeting(filepath1, filepath2, time_slot)
  # we get the data from the json files
  first_person_meetings = JSON.parse(File.read(filepath1))
  second_person_meetings = JSON.parse(File.read(filepath2))

  # we make arrays with the available slots for each person
  available_slots_first_person = get_available_slots(first_person_meetings)
  available_slots_second_person = get_available_slots(second_person_meetings)

  # we convert the time_slot from hours into minutes and make one array of all the available slots
  time_slot_minutes = time_slot * 60
  all_available_slots = available_slots_first_person.concat(available_slots_second_person)

  matching_slots = all_available_slots.each_with_object([]) do |available_slot, arr|
    # we convert the available spot into minutes
    hours = available_slot[:end_slot].hour - available_slot[:start_slot].hour
    minutes = available_slot[:end_slot].minute - available_slot[:start_slot].minute
    available_time = minutes + hours * 60
    # we check if the available time is enough for the time_slot we want
    if available_time >= time_slot_minutes
      # we create the right number of slot depending on the time_slot we want
      for i in 0...available_time / time_slot_minutes do
        arr << {
          start_slot: (available_slot[:start_slot].to_time + ((i * time_slot) * 3600)).to_datetime,
          end_slot: (available_slot[:start_slot].to_time + ((i * time_slot) * 3600) + (time_slot * 3600)).to_datetime
        }
      end
    end 
  end

  # we make a hash and count how many time there is the same available time slot
  counter_hash = Hash.new(0)
  matching_slots.each { |slot| counter_hash[slot] += 1 }
  # if the slot is more than once, it means the slot is available for both people, so we keep it
  counter_hash.select! { |k, v| v > 1 }
  final_slots = counter_hash.keys
end

def get_available_slots(person_meetings)
  available_slots = []

  # we initiate the current day for the start_day and end_day
  day = Date.parse(person_meetings.first["start"])
  start_day = DateTime.new(day.year, day.month, day.day, 9, 30, 0, '+02:00')
  end_day = DateTime.new(day.year, day.month, day.day, 18, 00, 0, '+02:00')

  available_slots << { start_slot: start_day, end_slot: DateTime.parse(person_meetings.first["start"]) }
  
  person_meetings.each_with_index do |slot, index|
    # if the day is different than the previous spot, we update the start and end day
    if index > 0 && DateTime.parse(slot["start"]).day != DateTime.parse(person_meetings[index - 1]["start"]).day
      day = Date.parse(slot["start"])
      start_day = DateTime.new(day.year, day.month, day.day, 9, 30, 0, '+02:00')
      end_day = DateTime.new(day.year, day.month, day.day, 18, 00, 0, '+02:00')
      
      # we push the first slot of the new day
      available_slots << { start_slot: start_day, end_slot: DateTime.parse(slot["start"]) }
    end
    if index < person_meetings.length - 1
      # if the current day is different than the next item, we insert the slot for the end of this day
      if DateTime.parse(slot['end']).day != DateTime.parse(person_meetings[index + 1]["end"]).day
        available_slots << { start_slot: DateTime.parse(slot["end"]), end_slot: end_day }
      end
      # if the current day is the same than the next item, we operate normally by creating a slot between 2 meetings
      if DateTime.parse(slot['start']).day == DateTime.parse(person_meetings[index + 1]['start']).day
        next_start_meeting = DateTime.parse(person_meetings[index + 1]["start"])
        end_meeting = DateTime.parse(slot["end"])
        available_slots << { start_slot: end_meeting, end_slot: next_start_meeting }
      end
    end
    # when we are a the final item, we insert the last slot
    if index == person_meetings.length - 1
      available_slots << { start_slot: DateTime.parse(slot["end"]), end_slot: end_day }
    end
  end

  available_slots
end

puts find_meeting('andrew_busy_slots.json', 'sandra_busy_slots.json', 1)
