# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy

class CaseOverviewItem(scrapy.Item):
    case_type = scrapy.Field()
    date = scrapy.Field()
    url = scrapy.Field()
    case_code = scrapy.Field()
    status = scrapy.Field()
    style = scrapy.Field()
    location = scrapy.Field()
    pass

class CasePartyItem(scrapy.Item):
    name = scrapy.Field()
    addr = scrapy.Field()
    case_code = scrapy.Field()
    party_side = scrapy.Field()
    others = scrapy.Field()
    removed = scrapy.Field()
    pass

class LawyerItem(scrapy.Item):
    name = scrapy.Field()
    status = scrapy.Field()
    case_code = scrapy.Field()
    party_name = scrapy.Field()
    striked = scrapy.Field()
    pass

class JudgmentItem(scrapy.Item):
    case_type = scrapy.Field()
    party = scrapy.Field()
    decision = scrapy.Field()
    case_code = scrapy.Field()
    date = scrapy.Field()
    pass

class FileItem(scrapy.Item):
    file_urls = scrapy.Field()
    files = scrapy.Field()
    case_code = scrapy.Field()
    pass

class EventItem(scrapy.Item):
    case_code = scrapy.Field()
    date = scrapy.Field()
    title = scrapy.Field()
    issued_date = scrapy.Field()
    signed_date = scrapy.Field()
    creation_date = scrapy.Field()
    status = scrapy.Field()
    status_date = scrapy.Field()
    officer = scrapy.Field()
    time = scrapy.Field()
    result = scrapy.Field()
    link = scrapy.Field()
    canceled = scrapy.Field()
    pass
