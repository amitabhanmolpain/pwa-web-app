from sqlalchemy import MetaData, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.db.models import Base

def init_db():
    """Initialize the database with tables from models"""
    engine = create_engine(settings.DATABASE_URL)
    Base.metadata.create_all(bind=engine)
    
    print("Database tables created successfully!")


if __name__ == "__main__":
    init_db()