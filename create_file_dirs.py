from sqlalchemy import create_engine
from sqlalchemy.engine.url import URL

import ojd_evictions.settings as settings
import os
import shutil


def main():
	dir_name = "work_party_files"
	work_party_dir = os.path.join(os.getcwd(),dir_name)
	if not os.path.exists(work_party_dir):
		os.mkdir(work_party_dir)

	engine = create_engine(URL(**settings.DATABASE))

	with engine.connect() as con:

	    rs = con.execute('SELECT * FROM files')

	for row in rs:
		print("Adding file for case " + row[1])
		case_dir = os.path.join(work_party_dir,row[1])

		if not os.path.exists(case_dir):
			os.mkdir(case_dir)

		src_file = os.path.join(settings.FILES_STORE,row[3])
		dest_file = os.path.join(case_dir,os.path.basename(row[3]))

		shutil.copyfile(src_file, dest_file)

if __name__ == "__main__":
	main()