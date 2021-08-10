from sqlalchemy.orm import sessionmaker
from ojd_evictions.models import CaseOverview, CaseParty, Lawyer, Judgment, File, Event, db_connect, create_tables
from ojd_evictions.items import CaseOverviewItem, CasePartyItem, LawyerItem, JudgmentItem, FileItem, EventItem

# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


class OjdEvictionsPipeline(object):
	def __init__(self):
		"""
		Initializes database connection and sessionmaker.
		Creates tables.
		"""
		engine = db_connect()

		# drop all tables
		try:
			CaseOverview.__table__.drop(engine)
		except:
			pass

		try:
			CaseParty.__table__.drop(engine)
		except:
			pass

		try:
			Lawyer.__table__.drop(engine)
		except:
			pass

		try:
			Judgment.__table__.drop(engine)
		except:
			pass

		try:
			File.__table__.drop(engine)
		except:
			pass

		try:
			Event.__table__.drop(engine)
		except:
			pass

		create_tables(engine)
		self.Session = sessionmaker(bind=engine)


	def process_item(self, item, spider):
		"""Save case in the database.

		This method is called for every item pipeline component.

		"""
		
		db_item_to_load = []

		# depending on the type of item, add it to the proper database table
		if isinstance(item, CaseOverviewItem):
			db_item_to_load.append(CaseOverview(**item))
		elif isinstance(item, CasePartyItem):
			db_item_to_load.append(CaseParty(**item))
		elif isinstance(item, LawyerItem):
			db_item_to_load.append(Lawyer(**item))
		elif isinstance(item, JudgmentItem):
			db_item_to_load.append(Judgment(**item))
		elif isinstance(item, EventItem):
			db_item_to_load.append(Event(**item))
		elif isinstance(item, FileItem):
			for downloaded_file in item['files']: # treated differently because this item represents multiple rows in the table
				db_item_to_load.append(File(
					case_code= item['case_code'],
					path = downloaded_file['path'],
					url = downloaded_file['url']
				))
		else:
			return item

		for db_item in db_item_to_load:
			session = self.Session()

			try:
				session.add(db_item)
				session.commit()
			except:
				session.rollback()
				raise
			finally:
				session.close()

		return item
