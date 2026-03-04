from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


class Item(BaseModel):
    name: str
    price: float


@app.get("/")
def read_root():
    return {
        "message": "Python CI/CD Demo App Running",
        "version": "2.0 - Dynamic Image Updates Enabled",
    }


@app.post("/items")
def create_item(item: Item):
    return {
        "name": item.name,
        "price": item.price,
        "tax": round(item.price * 0.1, 2),
    }
