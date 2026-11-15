import asyncio
from fastapi import HTTPException
import httpx
import os
from dotenv import load_dotenv

load_dotenv()

apis = [
    "https://cmr.earthdata.nasa.gov/search/collections.json?platform=SMAP",
    "https://cmr.earthdata.nasa.gov/search/granules.json",
    ]

async def obtener_mierdas(url:str):
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params={"platform":"SMAP", "page_size":99})

    if response.status_code != 200:
        raise HTTPException(status_code=502,detail="Error al consultar la API")
    
    data = response.json()
    entradas = data.get("feed", {}).get("entry", [])
    datasets_limpios = [[
            link.get("href")
            for link in item.get("links", [])
            if link.get("rel", "").endswith("/data#")]
    for item in entradas]

    with open("./output.txt","w") as file:
        for item in datasets_limpios:
            file.writelines(f"{item}\n" for item in item)
    # Limpiamos y devolvemos solo los campos que nos interesan
    return ( [
        {
            "id": item.get("id"),
            "short_name": item.get("short_name"),
            "title": item.get("title"),
            "time_start": item.get("time_start"),
        }
        for item in entradas
    ])
async def buscar_granules(url:str):
    token = os.getenv("NASA_EARTHDATA_TOKEN")
    headers = {"Authorization": f"Bearer {token}"}
    params = {
        "short_name": "SPL3SMP_E",
        "page_size": 5,
    }
    async with httpx.AsyncClient(follow_redirects=True) as client:
        response = await client.get(url, params=params, headers=headers)

        if response.status_code == 200:
            granules = response.json().get("feed", {}).get("entry", [])

            text = ""
            for granule in granules:
                for link in [x for x in granule.get("links", []) if x.get("rel", "").endswith("/data#")]:
                    verified_link = link.get("href")
                    if verified_link.endswith("h5") or verified_link.endswith("nc"):
                        text += verified_link + "\n"
            with open("./output2.txt","w") as file:
                file.write(text)
        else:
            print(f"error {response.status_code}")

if __name__ == "__main__":
    asyncio.run(obtener_mierdas(url=apis[0]))
    asyncio.run(buscar_granules(url=apis[1]))