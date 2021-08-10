import os
import psycopg2
from psycopg2 import sql
from datetime import date
import subprocess

today = date.today()

os.makedirs("S:\\AutoScrape\\AutoScrape_" + today.strftime("%m_%d_%Y"))

con = psycopg2.connect(
   database="postgres", user='postgres', password='admin', host='127.0.0.1', port= '5432'
)

con.autocommit = True

cur = con.cursor()

name_Database = "AutoScrape_" + today.strftime("%m_%d_%Y")

cur.execute("CREATE DATABASE "+name_Database+";")

#Closing the connection
con.close()

# call the crawl
os.system("scrapy crawl ojd-evictions-2020")

os.system("scrapy crawl ojd-evictions-2021")

# run r script to get tables and write to csv
command = "C:\\Program Files\\R\\R-4.0.5\\bin\\Rscript.exe"
path2script = "C:\\Users\\jdmac\\PycharmProjects\\odj-eviction-scraping-daily\\data_cleaning.R"

subprocess.call([command, path2script], shell=True)

# get file extenstions
cmd = "C:\\trid_w32\\trid.exe"
path2 = "S:\\AutoScrape\\AutoScrape_" + today.strftime("%m_%d_%Y") + "\\full\\*"
arg1 = "-ae"

subprocess.call([cmd, path2, arg1], shell=True)
