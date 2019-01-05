#!/usr/bin/python

from cbapi.response import CbResponseAPI, Process, Binary, Sensor
#
# Create our CbAPI object
#
c = CbResponseAPI()

query = c.select(Process).first()
print(query)
#
# take the first process that ran notepad.exe, download the binary and read the first two bytes
#
#c.select(Process).where('process_name:notepad.exe').first().binary.file.read(2)'MZ'
#c.select(Process).where('process_name:notepad.exe').first().binary.file.read(2)'MZ'
#
# if you want a specific ID, you can put it straight into the .select() call:
#
#binary = c.select(Binary, "24DA05ADE2A978E199875DA0D859E7EB")
#
# select all sensors that have ran notepad
#
#sensors = set()
#for proc in c.select(Process).where('process_name:evil.exe'):
#    sensors.add(proc.sensor)
#
# iterate over all sensors and isolate
#
#for s in sensors:
#    s.network_isolation_enabled = True
#    s.save()