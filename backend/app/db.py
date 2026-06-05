import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models import Base

DATABASE_URL = os.getenv('DATABASE_URL')
if DATABASE_URL is None:
    DATABASE_URL = 'sqlite:///./backend/test.db'
    engine = create_engine(DATABASE_URL, echo=False, future=True, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL, echo=False, future=True)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def init_db() -> None:
    Base.metadata.create_all(bind=engine)


def get_db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
