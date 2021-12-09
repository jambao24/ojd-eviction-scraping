1. Before you can scrape:
	1. Configure IDE - set up virtual environment and install required packages.
	2. Make sure the latest version of R is installed on your machine.
	3. Install PostgreSQL.
	4. Note that the scrape is set up to run on Windows - it could be modified to work on another OS but Windows is recommended.  
	

2. There are several ways to run the scraper.  A simple, automated approach, is to run 'run2021.py' or 'run2022.py' according to the year you want to scrape.  These py files are set to execute the following four processes: 
	1. create a PostgreSQL database, 
	2. run the scrape,  
	3. run R to pull the tables, and 
	4. create the flatfile.
		
The following is a description of the aforementioned four processes:
1.  The first process in run2022.py is to create the PostgreSQL database.  The database is named based on the year of the scrape and the date is was run.  In this case, a database created Jan 01 2022 would be named ojdevictions_2022_20220101.  This can also be created manually in the PostgreSQL GUI - pgAdmin.

run2022.py - line 13
```
con = psycopg2.connect(database="postgres", user='postgres', password='admin', host='127.0.0.1', port= '5432')  
con.autocommit = True  
cur = con.cursor()  
name_Database =  "ojdevictions_2022_" + today.strftime("%Y%m%d")  
cur.execute("CREATE database " + name_Database + ";")  
con.close()
```

2. The next step is to run the scrape.  This can be done manually in the terminal with the command: scrapy crawl ojd-evictions-2022.  This command tells scrapy to initiate crawling the spider named ojd-evictions-2022.  Open settings.py and make sure the scrape is writing to the correct database on or near line 41.  You may also want to open the spider file ojd_evictions_2022.py - this is the spider set to scrape all eviction cases that began in 2022.  Note the spiders name on line 22 is 'ojd-evictions-2022'.  This is the name to be used in calling the spider, not the file name.  Note that you can create custom spiders for specific date intervals.  Pay attention to the month_list on line 135 of the spider; the year on lines 198 & 199; and the CaseSearchValue on line 91.  For 2022 the CaseSearchValue will be set to '22LT*' - this is the wildcard search for all cases in 2022.  This is also a limiting factor that forces us to run the scrape separately for each year.  Ideally we could set the scrape to run multiple years at the same time but the OJCIN database query is not set up to receive multiple wildcards.  There may be a work around for this that we have yet to discover.  

run2022.py - line 23
```
cmd = "scrapy"  
arg1 = "crawl"  
arg2 = "ojd-evictions-2022"  
subprocess.call([cmd, arg1, arg2], shell = True)
```

3. The next step is to run the R script in the R_dataCleaning folder called flat_file_evictions.R - this will perform both steps (3) pull scrape tables from postgres & (4) make flatfile.  Make sure that in run2022.py, line 29 has command set to the location on your computer where R is installed and pointed to Rscript.exe.  Open flat_file_evictions.R and make sure lines 18 & 19 are set to the correct PostgreSQL database for each year you want to create the flatfile and pull the tables for.  Note that there is a better way to do this for multiple years (let Devin know and we can make these changes).  It is currently set to pull 2020 and the latest 2021 scrape.  The final part of this process is to write CSVs for all tables to "G:/Shared drives/ojdevictions/ScrapeData/full_scrape_YYYYmmdd".    

run2022.py - line 29
```
command = "C:\\Program Files\\R\\R-4.0.5\\bin\\Rscript.exe"  
path2script = "R_dataCleaning/flat_file_evictions.R"  
subprocess.call([command, path2script], shell=True)
```





Other notes on the scraper operation.

2. Manual scrape operation
    1. Get a Python IDE - I suggest [Pycharm](https://www.jetbrains.com/pycharm/).
    2. Open ojd-eviction-scraping project in Pycharm.
    3. Create a virtual environment and install packages from requirements.txt.
    4. The scraper is run separately for each year 2020 and 2021.
    5. In the settings file, make sure the postgres database is set to ojdevictions_2020 (see below).  The scraper output will be transferred to two individual postgres databases for each year 2020 and 2021 - these will be consolidated in the data cleaning step.     
    ```
    DATABASE = {  
    'drivername': 'postgres',  
    'host': 'localhost',  
    'port': '5432',  
    'username': 'postgres',   
    'password': 'admin',   
    'database': 'ojdevictions_2020' }
    ``` 
    5. In settings, set FILES_STORE to whatever directory you want to store downloaded documents - make sure to reset this location separately for each year.  In this case the files will be stored in the following directory within the project directory.
    ```
    FILES_STORE = r'CaseFile_Downloads\2020'
    ```
    6. Run the scraper from the top of the project directory with the following command:
    `scrapy crawl ojd-evictions-2020`
    7. If you get an error, check the working directory and try changing it with the cd command.
    8. When the scraper is finished, change the database name to ojdevictions_2021 and set FILES_STORE = r'CaseFile_Downloads\2021' before running the second spider.  (see settings below)
    ```
    DATABASE = {  
    'drivername': 'postgres',  
    'host': 'localhost',  
    'port': '5432',  
    'username': 'postgres',   
    'password': 'admin',   
    'database': 'ojdevictions_2021' }

    FILES_STORE = r'CaseFile_Downloads\2021'
    ```
3. Run the scraper again for 2021 using the following command: 
`scrapy crawl ojd-evictions-2021`
4. All data should now be populated in postgres.  Open pgAdmin to veiw the postgres tables.  These tables can be found by navigating to Servers/PostgreSQL/Databases /ojdevictions_2020 (or ojdevictions_2021)/Schemas/Tables; you should see 6 tables, case-overviews, case-parties, etc.
5. Note that if you do not want to download court documents from the scrape, turn off the FilesPipeline on line 84 of the settings.py file by preceding it with a #. 
6. Next, process the data and create a flat_file for the project using the r script in the R_dataCleaning directory of the project.  You will only need to run flat_file_evictions.R - but keep the other file (data_cleaning_evictions.R) it contains essential functions.
7. Run flat_file_evictions.R either in [RStudio](https://www.rstudio.com/products/rstudio/download/#download) ([go here to set up R](https://cran.r-project.org/)) or in the command line by finding the path for Rscript.exe and path to flat_file_evictions.R.  Something like this, depending on your local paths to R and the project:
```
C:\User> "C:\\Program Files\\R\\R-4.0.5\\bin\\Rscript.exe" "C:\\Project\\ojd-eviction-scraping\\R_dataCleaning\\flat_file_evictions.R"  
```
13. flat_file_evictions.R will create a folder in the same directory as the file called full_scrape_m_d_Y (m_d_Y will be populated by the date).  In this new folder you will find all the tables including the flat_file which will be sent to the R Shiny Web App.

![Scrape Process](Images/mermaid-diagram-20210811105426.png)