#!/usr/bin/env ruby

require 'httpclient'

class HavagResponseError < IOError; end


class Havag

    def getNextTrains
        hclnt = HavagClient.new('http://83.221.237.42:20010')
        body = [0x63, 0x00, 0x01, 0x6d, 0x00, 0x14, 0x67, 0x65, 0x74, 0x44, 0x65, 0x70, 0x61, 0x72, 0x74, 0x75, 0x72, 0x65, 0x73, 0x46, 0x6f, 0x72, 0x53, 0x74, 0x6f, 0x70, 0x53, 0x00, 0x07, 0x52, 0x65, 0x69, 0x6c, 0x65, 0x63, 0x6b, 0x7a]
        hres = hclnt.request(body)
        return hres.to_a
    end
end


class HavagClient

    @@headers = [['Content-Type', 'text/xml']]

    def initialize(server)
        @server = server
        @clnt = HTTPClient.new
    end

    def request(bytestream)
        puts @server
        puts bytestream
        puts @@headers
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
                output.last.push(value)
                next
            end

            data.shift
        end

        return output
    end
end


class Havag
end


if __FILE__ == $0
    havag = Havag.new
    puts havag.getNextTrains
end
