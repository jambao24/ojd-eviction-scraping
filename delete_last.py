import os
import psycopg2
from psycopg2 import sql
from datetime import date, timedelta
import shutil
import subprocess

today = date.today() # - timdelta(days=1)

# delete directory

dir_path = "G:\\Shared drives\\ojdevictions\\ScrapeData\\full_Scrape_" + today.strftime("%Y%m%d")

try:
    shutil.rmtree(dir_path)
except OSError as e:
    print("Error: %s : %s" % (dir_path, e.strerror))

# delete postgres database
con = psycopg2.connect(
    database="postgres", user='postgres', password='admin', host='127.0.0.1', port='5432'
)

con.autocommit = True

cur = con.cursor()

name_Database = "ojdevictions_" + today.strftime("%Y") + "_" + today.strftime("%Y%m%d")

cur.execute("DROP DATABASE " + name_Database + ";")

con.close()