#!/usr/bin/env python
import os
import sys
import time
from api import api

app=api()
app.start_serial("COM14")


ret=app.get_status()
print("-- Status: "+str(hex(ret)))

app.stop_serial()

