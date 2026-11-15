class ApiEndpoints {
  ApiEndpoints._();

  // TODO: confirmar con el backend
  static const parcelas = '/parcelas';

  // TODO: confirmar con el backend
  static String parcela(String id) => '/parcelas/$id';

  // TODO: confirmar con el backend
  static const aplicaciones = '/aplicaciones';

  // TODO: confirmar con el backend
  static String lluvia(String parcelaId) => '/parcelas/$parcelaId/lluvia';

  // TODO: confirmar con el backend
  static String riesgo(String parcelaId) => '/parcelas/$parcelaId/riesgo';

  // TODO: confirmar con el backend
  static String plots(String parcelaId) => '/parcelas/$parcelaId/plots';

  // TODO: confirmar con el backend
  static const alertas = '/alertas';
}
