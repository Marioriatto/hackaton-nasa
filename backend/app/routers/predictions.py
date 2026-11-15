from fastapi import APIRouter

router = APIRouter(prefix="/predictions", tags=["predictions"])


@router.get("")
async def listar_predicciones():
    return


@router.get("/{user_id}")
async def predicciones_por_usuario(user_id: str):
    return
