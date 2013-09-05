#!/usr/bin/env ruby
# encoding: utf-8

require 'httpclient'

class HavagResponseError < IOError; end


class Havag

    def initialize
        @hclnt = HavagClient.new('http://83.221.237.42:20010')
    end

    #private method
    def get(body)
        hres = @hclnt.request(body)
        return hres
    end

    def getNextTrains(station)
        body = [0x63, 0x00, 0x01, 0x6d, 0x00, 0x14, 0x67, 0x65,
                0x74, 0x44, 0x65, 0x70, 0x61, 0x72, 0x74, 0x75,
                0x72, 0x65, 0x73, 0x46, 0x6f, 0x72, 0x53, 0x74,
                0x6f, 0x70, 0x53, 0x00]
        body.push(station.length)
        station.bytes{ |b| body.push(b) }
        body.push(0x7a)

        result = Array.new
        self.get(body).to_a.each do |train|
            result.push({:line => train[0],
                         :destination => train[1],
                         :departure_real => DateTime.strptime(train[2], '%Y.%m.%d.%H:%M:%S'),
                         :departure_scheduled => DateTime.strptime(train[3], '%Y.%m.%d.%H:%M:%S'),
                         :low_floor => train[4],
                         :cab_id => train[6],
                         :station => train[10]})
        end

        #return self.get(body).to_a
        return result.sort { |x, y| x[:departure_real] <=> y[:departure_real] }
    end

    #Ergebnis ev. als Enumeration für vorhandene Eingabe der getNextTrains-method
    def getAllStations
        #Gibt alle Haltestellen der Havag zurück
        body = [0x63, 0x00, 0x01, 0x6d, 0x00, 0x0c, 0x67, 0x65,
                0x74, 0x53, 0x74, 0x6f, 0x70, 0x43, 0x6f, 0x64,
                0x65, 0x73, 0x7a]
        return self.get(body).to_a
    end
end

class HavagClient

    @@headers = [['Content-Type', 'text/xml']]

    def initialize(server)
        @server = server
        @clnt = HTTPClient.new
    end

    def request(bytestream)
        res = @clnt.post(@server + "/init/rtpi", (bytestream.map{ |c| c.chr}).join, @@headers)
        return HavagResponse.new(res.content)
    end
end


class HavagResponse < String

    @@rsplit = [0x56, 0x74, 0x00]
    @@csplit = [0x53, 0x00]

    def to_a
        data = Array.new
        output = Array.new

        self.encode!("ISO-8859-15", "UTF-8")
        self.bytes{ |b| data.push(b) }

        while data.length > 3 do
            if data[0] == @@rsplit[0] and data[1] == @@rsplit[1] and data[2] == @@rsplit[2] then
                data.shift(3)
                output.push(Array.new)
                next
            end

            if data[0] == @@csplit[0] and data[1] == @@csplit[1] then
                if output.empty? then
                    raise HavagResponseError.new('no dataset marker found while already retriving data')
                end
                data.shift(2)

                value = String.new
                (1..data.shift).each do |c|
                    value += data.shift.chr
                end
                output.last.push(value.encode("UTF-8", "ISO-8859-15"))
                next
            end

            data.shift
        end

        return output
    end
end


if __FILE__ == $0
    havag = Havag.new
    #puts havag.getNextTrains("Talstraße")
    puts havag.getAllStations
end
