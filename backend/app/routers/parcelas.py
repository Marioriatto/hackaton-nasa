from fastapi import APIRouter

router = APIRouter(prefix="/parcelas", tags=["parcelas"])


@router.get("")
async def listar_parcelas():
    return


@router.get("/{parcela_id}")
async def detalle_parcela(parcela_id: str):
    return


@router.get("/{parcela_id}/lluvia")
async def obtener_lluvia(parcela_id: str):
    return


@router.get("/{parcela_id}/riesgo")
async def obtener_riesgo(parcela_id: str):
    return


@router.get("/{parcela_id}/plots")
async def obtener_plots(parcela_id: str):
    return
