from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.engine.url import URL

import ojd_evictions.settings as settings


DeclarativeBase = declarative_base()


def db_connect():
    """
    Performs database connection using database settings from settings.py.
    Returns sqlalchemy engine instance
    """
    print(URL(**settings.DATABASE))
    return create_engine(URL(**settings.DATABASE))


def create_tables(engine):
    """"""
    DeclarativeBase.metadata.create_all(engine)


class CaseOverview(DeclarativeBase):
    """Sqlalchemy case-overviews model"""
    __tablename__ = "case-overviews"

    case_code = Column('case_code', String, primary_key=True)
    style = Column('style', String)
    case_type = Column('case_type', String)
    date = Column('date', String)
    url = Column('url', String)
    status = Column('status', String)
    location = Column('location', String)
    pass

class CaseParty(DeclarativeBase):
    """Sqlalchemy case-parties model"""
    __tablename__ = "case-parties"

    id = Column(Integer, primary_key = True)
    case_code = Column('case_code', String)
    name = Column('name', String)
    addr = Column('addr', String)
    others = Column('others', String)
    party_side = Column('party_side', String)
    removed = Column('removed', String)
    pass

class Lawyer(DeclarativeBase):
    """Sqlalchemy lawyers model"""
    __tablename__ = "lawyers"

    id = Column(Integer, primary_key = True)
    case_code = Column('case_code', String)
    party_name = Column('party_name', String)
    name = Column('name', String)
    status = Column('status', String)
    striked = Column('striked', Boolean)
    pass

class Judgment(DeclarativeBase):
    """Sqlalchemy judgments model"""
    __tablename__ = "judgments"

    id = Column(Integer, primary_key = True)
    case_code = Column('case_code', String)
    case_type = Column('case_type', String)
    party = Column('party', String)
    decision = Column('decision', String)
    date = Column('date', String)
    pass

class File(DeclarativeBase):
    """Sqlalchemy files model"""
    __tablename__ = "files"

    id = Column(Integer, primary_key = True)
    case_code = Column('case_code', String)
    url = Column('url', String)
    path = Column('path', String)
    pass

class Event(DeclarativeBase):
    """Sqlalchemy files model"""
    __tablename__ = "events"

    id = Column(Integer, primary_key = True)
    case_code = Column('case_code', String)
    date = Column('date', String)
    title = Column('title', String)
    issued_date = Column('issued_date', String)
    signed_date = Column('signed_date', String)
    creation_date = Column('creation_date', String)
    status_date = Column('status_date', String)
    status = Column('status', String)
    officer = Column('officer', String)
    time = Column('time', String)
    result = Column('result', String)
    link = Column('link', String)
    canceled = Column('canceled', String)
    pass