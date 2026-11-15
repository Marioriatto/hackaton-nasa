import os
from dotenv import load_dotenv
from sqlmodel import Field, Session, SQLModel, create_engine, select
from fastapi import Depends
from typing import Annotated
load_dotenv()

DATABASE_URL = f"postgresql://postgres:{os.getenv("DATABASE_PASSWORD")}@db.bzkeqmouswvxdzmmzmdg.supabase.co:5432/postgres"
engine = create_engine(url=DATABASE_URL, echo=True)

def get_session():
    with Session(engine) as session:
        yield session
def create_tables():
    SQLModel.metadata.create_all(engine)
SessionDep = Annotated[Session, Depends(get_session)]