from fastapi import APIRouter

router = APIRouter(prefix="/aplicaciones", tags=["aplicaciones"])


@router.post("")
async def registrar_aplicacion():
    return
