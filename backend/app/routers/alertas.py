from fastapi import APIRouter

router = APIRouter(prefix="/alertas", tags=["alertas"])


@router.get("")
async def listar_alertas():
    return
