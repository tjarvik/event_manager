require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
    phone_string = phone.to_s
    if phone_string.length > 11 || phone_string =~ /[^1]\d{10}/
        ""
    else
        phone_string.gsub(/[^\d]/,"")[-10..-1]
    end
end

def hours(raw_date)
    date = DateTime.strptime(raw_date, '%m/%d/%Y %H:%M')
    date.hour
end

def wdays(raw_date)
    date = DateTime.strptime(raw_date, '%m/%d/%Y %H:%M')
    date.wday
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    
    begin
        legislators = civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        "oops"
    end
end

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

def save_letters(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename,'w') do |file|
        file.puts form_letter
    end
end
popular_hours = {}
popular_wdays = {}

contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    phone = clean_phone(row[:homephone])

    hour = hours(row[:regdate])
    if popular_hours[hour]
        popular_hours[hour] += 1
    else 
        popular_hours[hour] = 1
    end
        
    wday = wdays(row[:regdate])
    if popular_wdays[wday]
        popular_wdays[wday] += 1
    else 
        popular_wdays[wday] = 1
    end

    #legislators = legislators_by_zipcode(zipcode)

    #form_letter = erb_template.result(binding)

    #save_letters(id, form_letter)
end

puts popular_hours.to_s
puts popular_wdays.to_s
