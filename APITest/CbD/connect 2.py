#!/usr/bin/python

from cbapi.defense.models import *
from cbapi.defense import *

# Create our Cb Defense API object
#
cb = CbDefenseAPI()
#
# Select any devices that have the hostname WIN-IA9NQ1GN8OI and an internal IP address of 192.168.215.150
#
eps = cb.select(Sensor)
#devices.refresh()
for ep in eds:
    print(ep.name)

