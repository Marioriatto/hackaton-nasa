import L from "leaflet";
import "leaflet/dist/leaflet.css";
import proj4 from "proj4";
import { useEffect, useMemo, useRef, useState } from "react";

export type Coordinate = [number, number];
export type MapProvider = "osm" | "google";
export type CoordinateSystem = "WGS84" | "CRTM05";

export type ParcelMetrics = {
  areaSquareMeters: number;
  areaHectares: number;
  perimeterMeters: number;
};

type ParcelBoundaryProps = {
  vertices: Coordinate[];
  closed: boolean;
  rainPoints?: { coordinate: Coordinate; precipitation: number; date: string }[];
  onVerticesChange: (vertices: Coordinate[]) => void;
  onClosedChange: (closed: boolean) => void;
};

type CoordinateRow = { x: string; y: string };

const GOOGLE_MAPS_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined;
const WGS84 = "EPSG:4326";
const CRTM05 =
  "+proj=tmerc +lat_0=0 +lon_0=-84 +k=0.9999 +x_0=500000 +y_0=0 +ellps=WGS84 +units=m +no_defs +type=crs";

proj4.defs("EPSG:5367", CRTM05);

function isFiniteCoordinate(point: Coordinate) {
  return (
    Number.isFinite(point[0]) &&
    Number.isFinite(point[1]) &&
    point[0] >= -180 &&
    point[0] <= 180 &&
    point[1] >= -90 &&
    point[1] <= 90
  );
}

function rowsFromVertices(vertices: Coordinate[], system: CoordinateSystem): CoordinateRow[] {
  return vertices.map(([longitude, latitude]) => {
    if (system === "WGS84") {
      return { x: longitude.toFixed(7), y: latitude.toFixed(7) };
    }
    const [x, y] = proj4(WGS84, "EPSG:5367", [longitude, latitude]);
    return { x: x.toFixed(3), y: y.toFixed(3) };
  });
}

function rowToWgs84(row: CoordinateRow, system: CoordinateSystem): Coordinate | null {
  const x = Number(row.x);
  const y = Number(row.y);
  if (!Number.isFinite(x) || !Number.isFinite(y) || row.x.trim() === "" || row.y.trim() === "") {
    return null;
  }
  const coordinate =
    system === "WGS84" ? ([x, y] as Coordinate) : (proj4("EPSG:5367", WGS84, [x, y]) as Coordinate);
  return isFiniteCoordinate(coordinate) ? coordinate : null;
}

function orientation(a: Coordinate, b: Coordinate, c: Coordinate) {
  return Math.sign((b[1] - a[1]) * (c[0] - b[0]) - (b[0] - a[0]) * (c[1] - b[1]));
}

function segmentsIntersect(a: Coordinate, b: Coordinate, c: Coordinate, d: Coordinate) {
  return (
    orientation(a, b, c) !== orientation(a, b, d) && orientation(c, d, a) !== orientation(c, d, b)
  );
}

export function polygonHasCrossings(vertices: Coordinate[]) {
  if (vertices.length < 4) return false;
  for (let first = 0; first < vertices.length; first += 1) {
    const firstNext = (first + 1) % vertices.length;
    for (let second = first + 1; second < vertices.length; second += 1) {
      const secondNext = (second + 1) % vertices.length;
      if (first === second || firstNext === second || secondNext === first) continue;
      if (
        segmentsIntersect(
          vertices[first],
          vertices[firstNext],
          vertices[second],
          vertices[secondNext],
        )
      )
        return true;
    }
  }
  return false;
}

function haversine(a: Coordinate, b: Coordinate) {
  const radius = 6371008.8;
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const latitudeDelta = toRadians(b[1] - a[1]);
  const longitudeDelta = toRadians(b[0] - a[0]);
  const latitudeA = toRadians(a[1]);
  const latitudeB = toRadians(b[1]);
  const h =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(latitudeA) * Math.cos(latitudeB) * Math.sin(longitudeDelta / 2) ** 2;
  return 2 * radius * Math.asin(Math.sqrt(h));
}

export function getParcelMetrics(vertices: Coordinate[]): ParcelMetrics | null {
  if (vertices.length < 3 || polygonHasCrossings(vertices)) return null;
  const radius = 6378137;
  const toRadians = (value: number) => (value * Math.PI) / 180;
  let areaSum = 0;
  let perimeter = 0;
  vertices.forEach((point, index) => {
    const next = vertices[(index + 1) % vertices.length];
    areaSum +=
      toRadians(next[0] - point[0]) *
      (2 + Math.sin(toRadians(point[1])) + Math.sin(toRadians(next[1])));
    perimeter += haversine(point, next);
  });
  const areaSquareMeters = Math.abs((areaSum * radius * radius) / 2);
  return {
    areaSquareMeters,
    areaHectares: areaSquareMeters / 10000,
    perimeterMeters: perimeter,
  };
}

export function parcelGeoJson(vertices: Coordinate[]) {
  if (vertices.length < 3 || polygonHasCrossings(vertices)) return null;
  return {
    type: "Feature" as const,
    properties: { name: "Parcela AquaDebt", coordinateReferenceSystem: "WGS84" },
    geometry: {
      type: "Polygon" as const,
      coordinates: [[...vertices, vertices[0]]],
    },
  };
}

export function ParcelBoundary({
  vertices,
  closed,
  rainPoints = [],
  onVerticesChange,
  onClosedChange,
}: ParcelBoundaryProps) {
  const [provider, setProvider] = useState<MapProvider>("osm");
  const [googleType, setGoogleType] = useState<"roadmap" | "satellite">("roadmap");
  const [method, setMethod] = useState<"coordinates" | "draw">("coordinates");
  const [system, setSystem] = useState<CoordinateSystem>("WGS84");
  const [rows, setRows] = useState<CoordinateRow[]>(() => rowsFromVertices(vertices, "WGS84"));
  const [drawing, setDrawing] = useState(false);
  const [googleError, setGoogleError] = useState("");
  const metrics = useMemo(() => (closed ? getParcelMetrics(vertices) : null), [closed, vertices]);
  const crossing = closed && polygonHasCrossings(vertices);
  const geometryValid = closed && vertices.length >= 3 && !crossing;

  useEffect(() => {
    setRows(rowsFromVertices(vertices, system));
  }, [system]);

  const changeProvider = (next: MapProvider) => {
    if (next === "google" && !GOOGLE_MAPS_API_KEY) {
      setGoogleError(
        "Google Maps no está disponible porque falta una API Key válida. OpenStreetMap continúa activo.",
      );
      setProvider("osm");
      return;
    }
    setGoogleError("");
    setProvider(next);
  };

  const applyRows = (nextRows: CoordinateRow[]) => {
    setRows(nextRows);
    const converted = nextRows.map((row) => rowToWgs84(row, system));
    if (converted.length >= 3 && converted.every(Boolean)) {
      onVerticesChange(converted as Coordinate[]);
      onClosedChange(true);
    } else {
      onClosedChange(false);
    }
  };

  const updateRow = (index: number, key: keyof CoordinateRow, value: string) => {
    const next = rows.map((row, rowIndex) => (rowIndex === index ? { ...row, [key]: value } : row));
    applyRows(next);
  };

  const removeVertex = (index: number) => {
    const nextVertices = vertices.filter((_, vertexIndex) => vertexIndex !== index);
    onVerticesChange(nextVertices);
    onClosedChange(nextVertices.length >= 3 && method === "coordinates");
    setRows(rowsFromVertices(nextVertices, system));
  };

  const startDrawing = () => {
    onVerticesChange([]);
    onClosedChange(false);
    setRows([]);
    setDrawing(true);
  };

  const handleMapVertices = (next: Coordinate[]) => {
    onVerticesChange(next);
    setRows(rowsFromVertices(next, system));
  };

  const closePolygon = () => {
    if (vertices.length >= 3) {
      onClosedChange(true);
      setDrawing(false);
    }
  };

  const deletePolygon = () => {
    onVerticesChange([]);
    onClosedChange(false);
    setRows([]);
    setDrawing(false);
  };

  const exportGeoJson = () => {
    const geoJson = parcelGeoJson(vertices);
    if (!geoJson) return;
    const blob = new Blob([JSON.stringify(geoJson, null, 2)], { type: "application/geo+json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "parcela-aquadebt-wgs84.geojson";
    anchor.click();
    URL.revokeObjectURL(url);
  };

  return (
    <section className="boundary-module">
      <div className="boundary-heading">
        <div>
          <span className="module-kicker">Delimitación de parcela</span>
          <h2>Define el terreno agrícola</h2>
          <p>La geometría se conserva en WGS84 y se muestra igual en ambos proveedores.</p>
        </div>
        <span className={`geometry-state ${geometryValid ? "ready" : ""}`}>
          {geometryValid
            ? `${vertices.length} vértices · geometría válida`
            : "Parcela sin delimitar"}
        </span>
      </div>

      <div className="provider-controls">
        <div className="control-group">
          <span>Proveedor cartográfico</span>
          <div className="compact-segmented">
            <button
              className={provider === "osm" ? "active" : ""}
              onClick={() => changeProvider("osm")}
            >
              OpenStreetMap
            </button>
            <button
              className={provider === "google" ? "active" : ""}
              onClick={() => changeProvider("google")}
            >
              Google Maps
            </button>
          </div>
        </div>
        {provider === "google" && (
          <div className="control-group">
            <span>Vista de Google</span>
            <div className="compact-segmented">
              <button
                className={googleType === "roadmap" ? "active" : ""}
                onClick={() => setGoogleType("roadmap")}
              >
                Calles
              </button>
              <button
                className={googleType === "satellite" ? "active" : ""}
                onClick={() => setGoogleType("satellite")}
              >
                Satélite
              </button>
            </div>
          </div>
        )}
      </div>
      {googleError && (
        <div className="provider-message" role="status">
          {googleError}
        </div>
      )}
      {provider === "google" && googleType === "satellite" && (
        <div className="cartography-note">
          La vista satelital de Google es únicamente cartografía de fondo; no es una medición
          ambiental ni una observación NASA.
        </div>
      )}

      <div className="boundary-map-wrap">
        {provider === "osm" ? (
          <OpenStreetMap
            vertices={vertices}
            closed={closed}
            drawing={drawing}
            rainPoints={rainPoints}
            onVerticesChange={handleMapVertices}
          />
        ) : (
          <GoogleParcelMap
            apiKey={GOOGLE_MAPS_API_KEY || ""}
            mapType={googleType}
            vertices={vertices}
            closed={closed}
            drawing={drawing}
            rainPoints={rainPoints}
            onVerticesChange={handleMapVertices}
            onError={(message) => {
              setGoogleError(message);
              setProvider("osm");
            }}
          />
        )}
        <div className="map-legend boundary-legend">
          <strong>Leyenda</strong>
          <span>
            <i className="dot-green" /> Límite de parcela
          </span>
          <span>
            <i className="dot-blue" /> Vértices editables
          </span>
          <span>
            <i className="dot-gray" /> Acuíferos: no disponible
          </span>
        </div>
      </div>

      <div className="boundary-workspace">
        <div className="method-panel">
          <div className="method-tabs">
            <button
              className={method === "coordinates" ? "active" : ""}
              onClick={() => {
                setMethod("coordinates");
                setDrawing(false);
              }}
            >
              1. Ingresar coordenadas
            </button>
            <button className={method === "draw" ? "active" : ""} onClick={() => setMethod("draw")}>
              2. Dibujar en el mapa
            </button>
          </div>
          {method === "coordinates" ? (
            <div className="coordinate-editor">
              <div className="editor-intro">
                <div>
                  <strong>Vértices del plano catastrado</strong>
                  <p>X e Y se interpretan según el sistema seleccionado.</p>
                </div>
                <label>
                  Sistema
                  <select
                    value={system}
                    onChange={(event) => setSystem(event.target.value as CoordinateSystem)}
                  >
                    <option value="WGS84">WGS84 (X=longitud, Y=latitud)</option>
                    <option value="CRTM05">CRTM05 / EPSG:5367 (metros)</option>
                  </select>
                </label>
              </div>
              <div className="vertex-table-wrap">
                <table className="vertex-table">
                  <thead>
                    <tr>
                      <th>Punto</th>
                      <th>Coordenada X</th>
                      <th>Coordenada Y</th>
                      <th>
                        <span className="sr-only">Acciones</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row, index) => (
                      <tr key={index}>
                        <td>P{index + 1}</td>
                        <td>
                          <input
                            aria-label={`Coordenada X del punto ${index + 1}`}
                            inputMode="decimal"
                            value={row.x}
                            onChange={(event) => updateRow(index, "x", event.target.value)}
                          />
                        </td>
                        <td>
                          <input
                            aria-label={`Coordenada Y del punto ${index + 1}`}
                            inputMode="decimal"
                            value={row.y}
                            onChange={(event) => updateRow(index, "y", event.target.value)}
                          />
                        </td>
                        <td>
                          <button
                            className="remove-vertex"
                            onClick={() => removeVertex(index)}
                            aria-label={`Eliminar punto ${index + 1}`}
                          >
                            ×
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <button
                className="add-vertex"
                onClick={() => {
                  setRows([...rows, { x: "", y: "" }]);
                  onClosedChange(false);
                }}
              >
                + Agregar vértice
              </button>
              {rows.length > 0 && rows.some((row) => !rowToWgs84(row, system)) && (
                <p className="coordinate-error">
                  Completa coordenadas válidas. WGS84 usa X=longitud (−180 a 180) y Y=latitud (−90 a
                  90).
                </p>
              )}
              {rows.length > 0 && rows.length < 3 && (
                <p className="coordinate-error">
                  Se requieren al menos tres vértices para generar el polígono.
                </p>
              )}
            </div>
          ) : (
            <div className="draw-tools">
              <div>
                <strong>Dibujo directo</strong>
                <p>
                  Activa el dibujo y haz clic en el mapa. Arrastra los vértices para ajustarlos.
                </p>
              </div>
              <div className="draw-actions">
                <button className="tool-button" onClick={startDrawing}>
                  {vertices.length ? "Dibujar de nuevo" : "Iniciar dibujo"}
                </button>
                <button
                  className="tool-button primary-tool"
                  disabled={!drawing || vertices.length < 3}
                  onClick={closePolygon}
                >
                  Cerrar polígono
                </button>
                <button
                  className="tool-button danger-tool"
                  disabled={!vertices.length}
                  onClick={deletePolygon}
                >
                  Eliminar
                </button>
              </div>
              <p className="draw-status">
                {drawing
                  ? `${vertices.length} vértices agregados. ${vertices.length < 3 ? "Agrega al menos tres." : "Ya puedes cerrar el polígono."}`
                  : closed
                    ? "Polígono cerrado. Sus vértices continúan editables."
                    : "Activa la herramienta para comenzar."}
              </p>
            </div>
          )}
        </div>

        <aside className="geometry-results">
          <span className="module-kicker">Resultados geográficos</span>
          {metrics && geometryValid ? (
            <>
              <dl>
                <div>
                  <dt>Área</dt>
                  <dd>{formatMetric(metrics.areaHectares, 4)} ha</dd>
                </div>
                <div>
                  <dt>Área</dt>
                  <dd>{formatMetric(metrics.areaSquareMeters, 2)} m²</dd>
                </div>
                <div>
                  <dt>Perímetro</dt>
                  <dd>{formatMetric(metrics.perimeterMeters, 2)} m</dd>
                </div>
                <div>
                  <dt>Referencia</dt>
                  <dd>GeoJSON WGS84</dd>
                </div>
              </dl>
              <button className="export-button" onClick={exportGeoJson}>
                Exportar GeoJSON
              </button>
              <p className="spatial-link">
                {rainPoints.length
                  ? `${rainPoints.length} referencia(s) GPM georreferenciada(s) visible(s) a escala regional.`
                  : "El archivo de precipitación no aporta coordenadas para una relación espacial visible."}
              </p>
            </>
          ) : (
            <div className="no-geometry">
              <strong>Sin resultados</strong>
              <p>
                {crossing
                  ? "El polígono presenta cruces entre límites. Ajusta sus vértices."
                  : "Delimita una parcela válida para calcular área y perímetro."}
              </p>
            </div>
          )}
        </aside>
      </div>
    </section>
  );
}

function OpenStreetMap({
  vertices,
  closed,
  drawing,
  rainPoints,
  onVerticesChange,
}: {
  vertices: Coordinate[];
  closed: boolean;
  drawing: boolean;
  rainPoints: { coordinate: Coordinate; precipitation: number; date: string }[];
  onVerticesChange: (vertices: Coordinate[]) => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const layerRef = useRef<L.LayerGroup | null>(null);
  const verticesRef = useRef(vertices);
  const drawingRef = useRef(drawing);
  const onChangeRef = useRef(onVerticesChange);

  verticesRef.current = vertices;
  drawingRef.current = drawing;
  onChangeRef.current = onVerticesChange;

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    const map = L.map(containerRef.current, { zoomControl: true }).setView([0, 0], 2);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      maxZoom: 20,
    }).addTo(map);
    const group = L.layerGroup().addTo(map);
    map.on("click", (event) => {
      if (!drawingRef.current) return;
      onChangeRef.current([...verticesRef.current, [event.latlng.lng, event.latlng.lat]]);
    });
    mapRef.current = map;
    layerRef.current = group;
    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    const group = layerRef.current;
    if (!map || !group) return;
    group.clearLayers();
    rainPoints.forEach((point) => {
      L.circle([point.coordinate[1], point.coordinate[0]], {
        radius: 5000,
        color: "#1d89a6",
        weight: 2,
        fillColor: "#1d89a6",
        fillOpacity: 0.14,
      })
        .bindTooltip(`${point.date}: ${point.precipitation} mm · referencia regional GPM`)
        .addTo(group);
    });
    if (!vertices.length) return;
    const latLngs = vertices.map(([longitude, latitude]) => L.latLng(latitude, longitude));
    if (closed && vertices.length >= 3) {
      L.polygon(latLngs, {
        color: "#23845f",
        weight: 3,
        fillColor: "#23845f",
        fillOpacity: 0.18,
      }).addTo(group);
    } else if (vertices.length >= 2) {
      L.polyline(latLngs, { color: "#23845f", weight: 3, dashArray: "8 6" }).addTo(group);
    }
    vertices.forEach(([longitude, latitude], index) => {
      const marker = L.marker([latitude, longitude], {
        draggable: true,
        icon: L.divIcon({
          className: "parcel-vertex-icon",
          html: `<span>${index + 1}</span>`,
          iconSize: [24, 24],
          iconAnchor: [12, 12],
        }),
      }).addTo(group);
      marker.on("dragend", () => {
        const position = marker.getLatLng();
        const next = verticesRef.current.map((point, pointIndex) =>
          pointIndex === index ? ([position.lng, position.lat] as Coordinate) : point,
        );
        onChangeRef.current(next);
      });
      marker.on("contextmenu", () => {
        if (verticesRef.current.length <= 3) return;
        onChangeRef.current(verticesRef.current.filter((_, pointIndex) => pointIndex !== index));
      });
    });
    if (closed && vertices.length >= 3) {
      vertices.forEach((point, index) => {
        const nextIndex = (index + 1) % vertices.length;
        const next = vertices[nextIndex];
        const midpoint: Coordinate = [(point[0] + next[0]) / 2, (point[1] + next[1]) / 2];
        const midpointMarker = L.marker([midpoint[1], midpoint[0]], {
          icon: L.divIcon({
            className: "parcel-midpoint-icon",
            html: "<span>+</span>",
            iconSize: [18, 18],
            iconAnchor: [9, 9],
          }),
        }).addTo(group);
        midpointMarker.on("click", () => {
          const updated = [...verticesRef.current];
          updated.splice(nextIndex, 0, midpoint);
          onChangeRef.current(updated);
        });
      });
    }
    if (vertices.length === 1) map.setView(latLngs[0], 16);
    else map.fitBounds(L.latLngBounds(latLngs), { padding: [45, 45], maxZoom: 18 });
  }, [closed, rainPoints, vertices]);

  return (
    <div
      ref={containerRef}
      className={`interactive-map ${drawing ? "is-drawing" : ""}`}
      aria-label="Mapa interactivo OpenStreetMap"
    />
  );
}

let googleMapsPromise: Promise<void> | null = null;

function loadGoogleMaps(apiKey: string) {
  if (typeof google !== "undefined" && google.maps) return Promise.resolve();
  if (googleMapsPromise) return googleMapsPromise;
  googleMapsPromise = new Promise((resolve, reject) => {
    const callback = `initAquaDebtGoogleMaps${Date.now()}`;
    const timeout = window.setTimeout(
      () => reject(new Error("No fue posible validar o cargar Google Maps.")),
      12000,
    );
    const dynamicWindow = window as unknown as Record<string, unknown>;
    dynamicWindow[callback] = () => {
      window.clearTimeout(timeout);
      resolve();
      delete dynamicWindow[callback];
    };
    dynamicWindow.gm_authFailure = () => {
      window.clearTimeout(timeout);
      reject(
        new Error("La API Key de Google Maps no es válida o no está autorizada para este sitio."),
      );
      window.dispatchEvent(new CustomEvent("aquadebt-google-auth-failure"));
    };
    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}&callback=${callback}&v=weekly`;
    script.async = true;
    script.onerror = () =>
      reject(new Error("No fue posible cargar Google Maps. OpenStreetMap continúa disponible."));
    document.head.appendChild(script);
  });
  return googleMapsPromise;
}

function GoogleParcelMap({
  apiKey,
  mapType,
  vertices,
  closed,
  drawing,
  rainPoints,
  onVerticesChange,
  onError,
}: {
  apiKey: string;
  mapType: "roadmap" | "satellite";
  vertices: Coordinate[];
  closed: boolean;
  drawing: boolean;
  rainPoints: { coordinate: Coordinate; precipitation: number; date: string }[];
  onVerticesChange: (vertices: Coordinate[]) => void;
  onError: (message: string) => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<google.maps.Map | null>(null);
  const shapeRef = useRef<google.maps.Polygon | google.maps.Polyline | null>(null);
  const rainOverlaysRef = useRef<google.maps.Circle[]>([]);
  const verticesRef = useRef(vertices);
  const drawingRef = useRef(drawing);
  const onChangeRef = useRef(onVerticesChange);
  const [mapReady, setMapReady] = useState(false);
  verticesRef.current = vertices;
  drawingRef.current = drawing;
  onChangeRef.current = onVerticesChange;

  useEffect(() => {
    let cancelled = false;
    const handleAuthenticationFailure = () =>
      onError("La API Key de Google Maps no es válida o no está autorizada para este sitio.");
    window.addEventListener("aquadebt-google-auth-failure", handleAuthenticationFailure);
    loadGoogleMaps(apiKey)
      .then(() => {
        if (cancelled || !containerRef.current) return;
        const map = new google.maps.Map(containerRef.current, {
          center: { lat: 0, lng: 0 },
          zoom: 2,
          mapTypeId: mapType,
          streetViewControl: false,
          fullscreenControl: false,
          mapTypeControl: false,
        });
        map.addListener("click", (event: google.maps.MapMouseEvent) => {
          if (!drawingRef.current || !event.latLng) return;
          onChangeRef.current([...verticesRef.current, [event.latLng.lng(), event.latLng.lat()]]);
        });
        mapRef.current = map;
        setMapReady(true);
      })
      .catch((error: Error) => onError(error.message));
    return () => {
      cancelled = true;
      window.removeEventListener("aquadebt-google-auth-failure", handleAuthenticationFailure);
      shapeRef.current?.setMap(null);
      rainOverlaysRef.current.forEach((overlay) => overlay.setMap(null));
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    mapRef.current?.setMapTypeId(mapType);
  }, [mapType]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || typeof google === "undefined" || !google.maps) return;
    shapeRef.current?.setMap(null);
    rainOverlaysRef.current.forEach((overlay) => overlay.setMap(null));
    rainOverlaysRef.current = rainPoints.map(
      (point) =>
        new google.maps.Circle({
          map,
          center: { lng: point.coordinate[0], lat: point.coordinate[1] },
          radius: 5000,
          strokeColor: "#1d89a6",
          strokeWeight: 2,
          fillColor: "#1d89a6",
          fillOpacity: 0.14,
        }),
    );
    if (!vertices.length) return;
    const path = vertices.map(([longitude, latitude]) => ({ lng: longitude, lat: latitude }));
    let shape: google.maps.Polygon | google.maps.Polyline;
    if (closed && vertices.length >= 3) {
      shape = new google.maps.Polygon({
        map,
        paths: path,
        editable: true,
        draggable: false,
        strokeColor: "#23845f",
        strokeWeight: 3,
        fillColor: "#23845f",
        fillOpacity: 0.18,
      });
    } else {
      shape = new google.maps.Polyline({
        map,
        path,
        editable: true,
        strokeColor: "#23845f",
        strokeWeight: 3,
      });
    }
    const editablePath = shape.getPath();
    const syncPath = () => {
      const next: Coordinate[] = [];
      for (let index = 0; index < editablePath.getLength(); index += 1) {
        const point = editablePath.getAt(index);
        next.push([point.lng(), point.lat()]);
      }
      onChangeRef.current(next);
    };
    editablePath.addListener("set_at", syncPath);
    editablePath.addListener("insert_at", syncPath);
    editablePath.addListener("remove_at", syncPath);
    shapeRef.current = shape;
    const bounds = new google.maps.LatLngBounds();
    path.forEach((point) => bounds.extend(point));
    if (path.length === 1) {
      map.setCenter(path[0]);
      map.setZoom(16);
    } else {
      map.fitBounds(bounds, 45);
    }
  }, [closed, mapReady, rainPoints, vertices]);

  return (
    <div
      ref={containerRef}
      className={`interactive-map ${drawing ? "is-drawing" : ""}`}
      aria-label="Mapa interactivo Google Maps"
    />
  );
}

function formatMetric(value: number, decimals: number) {
  return new Intl.NumberFormat("es-CR", {
    maximumFractionDigits: decimals,
    minimumFractionDigits: Math.min(decimals, 2),
  }).format(value);
}
