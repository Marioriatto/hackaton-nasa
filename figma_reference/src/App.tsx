import { ChangeEvent, FormEvent, ReactNode, useMemo, useState } from "react";
import { Coordinate, getParcelMetrics, ParcelBoundary, parcelGeoJson } from "./ParcelBoundary";

type Page = "inicio" | "mapa" | "registro" | "resultados";
type DataMode = "real" | "demo";
type ResultView = "actual" | "a" | "b" | "incompleto";

type RecordData = {
  name: string;
  location: string;
  crop: string;
  fertilizer: string;
  applicationDate: string;
  dose: string;
  doseUnit: string;
  latitude: string;
  longitude: string;
};

type RainRow = {
  date: string;
  precipitation: number;
  latitude?: string;
  longitude?: string;
  source?: string;
  product?: string;
  resolution?: string;
};

type RainData = {
  fileName: string;
  rows: RainRow[];
  unit: string;
  source: string;
  product: string;
  resolution: string;
};

type Config = {
  recentDays: string;
  relevantRain: string;
  useIntermediate: boolean;
  intermediateRain: string;
  lowMax: string;
  moderateMax: string;
};

const emptyRecord: RecordData = {
  name: "Parcela demostrativa",
  location: "El Encinar, Guanacaste, Costa Rica",
  crop: "Soya",
  fertilizer: "",
  applicationDate: "",
  dose: "",
  doseUnit: "",
  latitude: "",
  longitude: "",
};

const emptyConfig: Config = {
  recentDays: "",
  relevantRain: "",
  useIntermediate: false,
  intermediateRain: "",
  lowMax: "",
  moderateMax: "",
};

const icons = {
  leaf: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M19.7 4.3C13.3 4 8.6 5.9 6.2 9.2c-1.6 2.2-1.4 5.1.4 7 4.8-5.6 9.5-7.5 9.5-7.5s-4.5 2.8-7.9 8.8c2.3.9 4.9.2 6.5-1.8 2.3-2.8 3.3-6.8 5-11.4Z" />
    </svg>
  ),
  satellite: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="m9 15 6-6m-4.5 3.5 1 1M5 3l4 4-2 2-4-4 2-2Zm14 16-4-4 2-2 4 4-2 2ZM14 4l6 6-2 2-6-6 2-2ZM4 14l6 6-2 2-6-6 2-2Z" />
    </svg>
  ),
  shield: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3 5 6v5c0 4.7 2.8 8.4 7 10 4.2-1.6 7-5.3 7-10V6l-7-3Z" />
      <path d="m9 12 2 2 4-4" />
    </svg>
  ),
  water: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 2S5.5 9.4 5.5 14a6.5 6.5 0 0 0 13 0C18.5 9.4 12 2 12 2Z" />
      <path d="M9 15.2c.4 1.3 1.4 2.1 2.8 2.3" />
    </svg>
  ),
  pin: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z" />
      <circle cx="12" cy="10" r="2.5" />
    </svg>
  ),
  arrow: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M5 12h14m-5-5 5 5-5 5" />
    </svg>
  ),
  upload: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 16V4m-4 4 4-4 4 4M5 14v5h14v-5" />
    </svg>
  ),
  warning: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3 2.8 20h18.4L12 3Z" />
      <path d="M12 9v5m0 3h.01" />
    </svg>
  ),
  check: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="9" />
      <path d="m8 12 2.5 2.5L16 9" />
    </svg>
  ),
};

function Icon({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <span className={`icon ${className}`}>{children}</span>;
}

function App() {
  const [page, setPage] = useState<Page>("inicio");
  const [mobileNav, setMobileNav] = useState(false);
  const [record, setRecord] = useState<RecordData>(emptyRecord);
  const [savedRecord, setSavedRecord] = useState<RecordData | null>(null);
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [savedNotice, setSavedNotice] = useState(false);
  const [dataMode, setDataMode] = useState<DataMode>("real");
  const [rainData, setRainData] = useState<RainData | null>(null);
  const [fileError, setFileError] = useState("");
  const [config, setConfig] = useState<Config>(emptyConfig);
  const [resultView, setResultView] = useState<ResultView>("actual");
  const [demoScenario, setDemoScenario] = useState<"a" | "b">("a");
  const [parcelVertices, setParcelVertices] = useState<Coordinate[]>([]);
  const [parcelClosed, setParcelClosed] = useState(false);

  const navigate = (target: Page) => {
    setPage(target);
    setMobileNav(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const validateRecord = () => {
    const errors: Record<string, string> = {};
    if (!record.name.trim()) errors.name = "Ingresa el nombre de la parcela.";
    if (!record.fertilizer.trim())
      errors.fertilizer = "Indica el tipo de fertilizante nitrogenado.";
    if (!record.applicationDate) {
      errors.applicationDate = "Selecciona la fecha de aplicación.";
    } else if (Number.isNaN(new Date(`${record.applicationDate}T12:00:00`).getTime())) {
      errors.applicationDate = "La fecha ingresada no es válida.";
    } else if (new Date(`${record.applicationDate}T12:00:00`) > new Date()) {
      errors.applicationDate = "La fecha de aplicación no puede estar en el futuro.";
    }
    if ((record.latitude && !record.longitude) || (!record.latitude && record.longitude)) {
      errors.coordinates = "Completa ambas coordenadas o deja ambas vacías.";
    } else if (
      record.latitude &&
      (Number(record.latitude) < -90 ||
        Number(record.latitude) > 90 ||
        Number(record.longitude) < -180 ||
        Number(record.longitude) > 180)
    ) {
      errors.coordinates = "Revisa los rangos: latitud −90 a 90 y longitud −180 a 180.";
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const saveRecord = (goToResults = false) => {
    if (!validateRecord()) return;
    setSavedRecord({ ...record });
    setSavedNotice(true);
    if (goToResults) {
      setResultView("actual");
      navigate("resultados");
    }
  };

  const parseRainFile = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    setFileError("");
    setRainData(null);
    if (!file) return;
    try {
      const text = await file.text();
      let rawRows: Record<string, unknown>[] = [];
      if (file.name.toLowerCase().endsWith(".json")) {
        const parsed = JSON.parse(text);
        rawRows = Array.isArray(parsed) ? parsed : Array.isArray(parsed.data) ? parsed.data : [];
      } else if (file.name.toLowerCase().endsWith(".csv")) {
        const lines = text.trim().split(/\r?\n/);
        const headers = lines[0]?.split(",").map((item) => item.trim());
        if (!headers.includes("date") || !headers.includes("precipitation_mm")) {
          throw new Error("El CSV debe incluir las columnas date y precipitation_mm.");
        }
        rawRows = lines
          .slice(1)
          .filter(Boolean)
          .map((line) => {
            const values = line.split(",").map((item) => item.trim());
            return Object.fromEntries(headers.map((header, index) => [header, values[index]]));
          });
      } else {
        throw new Error("Formato no compatible. Carga un archivo CSV o JSON.");
      }
      if (!rawRows.length) throw new Error("El archivo no contiene registros de precipitación.");
      if (!rawRows.every((row) => "date" in row && "precipitation_mm" in row)) {
        throw new Error(
          "Cada registro debe incluir date y precipitation_mm; la unidad esperada es mm.",
        );
      }
      const rows: RainRow[] = rawRows.map((row, index) => {
        const date = String(row.date ?? "");
        const precipitation = Number(row.precipitation_mm);
        if (!date || Number.isNaN(new Date(`${date}T12:00:00`).getTime())) {
          throw new Error(`La fecha de la fila ${index + 1} no es válida.`);
        }
        if (!Number.isFinite(precipitation) || precipitation < 0) {
          throw new Error(
            `La precipitación de la fila ${index + 1} debe ser un número igual o mayor que 0.`,
          );
        }
        return {
          date,
          precipitation,
          latitude: row.latitude ? String(row.latitude) : undefined,
          longitude: row.longitude ? String(row.longitude) : undefined,
          source: row.source ? String(row.source) : undefined,
          product: row.product ? String(row.product) : undefined,
          resolution: row.resolution ? String(row.resolution) : undefined,
        };
      });
      const first = rows[0];
      setRainData({
        fileName: file.name,
        rows,
        unit: "mm",
        source: first.source || "Fuente no indicada en el archivo",
        product: first.product || "Producto no indicado en el archivo",
        resolution: first.resolution || "Resolución no indicada en el archivo",
      });
    } catch (error) {
      setFileError(error instanceof Error ? error.message : "No fue posible leer el archivo.");
    } finally {
      event.target.value = "";
    }
  };

  const rainPeriod = rainData
    ? `${rainData.rows.map((row) => row.date).sort()[0]} — ${rainData.rows
        .map((row) => row.date)
        .sort()
        .at(-1)}`
    : "Información de precipitación no disponible";

  return (
    <div className="app-shell">
      <header className="site-header">
        <div className="header-inner">
          <button className="brand" onClick={() => navigate("inicio")} aria-label="Ir al inicio">
            <span className="brand-mark">
              <Icon>{icons.water}</Icon>
              <span className="brand-leaf">
                <Icon>{icons.leaf}</Icon>
              </span>
            </span>
            <span>
              Aqua<span>Debt</span>
            </span>
          </button>
          <button
            className="menu-button"
            onClick={() => setMobileNav((open) => !open)}
            aria-expanded={mobileNav}
            aria-label="Abrir navegación"
          >
            <span />
            <span />
            <span />
          </button>
          <nav
            className={mobileNav ? "main-nav open" : "main-nav"}
            aria-label="Navegación principal"
          >
            {(
              [
                ["inicio", "Inicio"],
                ["mapa", "Mapa"],
                ["registro", "Registro agrícola"],
                ["resultados", "Resultados"],
              ] as [Page, string][]
            ).map(([target, label]) => (
              <button
                key={target}
                className={page === target ? "active" : ""}
                onClick={() => navigate(target)}
              >
                {label}
              </button>
            ))}
          </nav>
          <div className="pilot-chip">
            <span /> Caso piloto: El Encinar
          </div>
        </div>
      </header>

      <main>
        {page === "inicio" && <Home onNavigate={navigate} />}
        {page === "mapa" && (
          <MapPage
            record={record}
            parcelVertices={parcelVertices}
            setParcelVertices={setParcelVertices}
            parcelClosed={parcelClosed}
            setParcelClosed={setParcelClosed}
            dataMode={dataMode}
            setDataMode={setDataMode}
            rainData={rainData}
            fileError={fileError}
            onFile={parseRainFile}
            config={config}
            setConfig={setConfig}
            demoScenario={demoScenario}
            setDemoScenario={setDemoScenario}
            rainPeriod={rainPeriod}
            onNavigate={navigate}
          />
        )}
        {page === "registro" && (
          <RegisterPage
            record={record}
            setRecord={setRecord}
            errors={formErrors}
            savedRecord={savedRecord}
            savedNotice={savedNotice}
            parcelVertices={parcelVertices}
            parcelClosed={parcelClosed}
            onSave={() => saveRecord(false)}
            onEvaluate={() => saveRecord(true)}
            onNavigate={navigate}
          />
        )}
        {page === "resultados" && (
          <ResultsPage
            record={savedRecord || record}
            hasSavedRecord={Boolean(savedRecord)}
            dataMode={dataMode}
            rainData={rainData}
            config={config}
            resultView={resultView}
            setResultView={setResultView}
            demoScenario={demoScenario}
            rainPeriod={rainPeriod}
            onNavigate={navigate}
          />
        )}
      </main>
      <footer>
        <div>
          <strong>AquaDebt</strong> | NASA Space Apps Challenge
        </div>
        <p>
          El indicador identifica condiciones potenciales de transporte de nutrientes; no confirma
          contaminación del agua subterránea ni sustituye análisis de laboratorio o asesoría
          profesional.
        </p>
      </footer>
    </div>
  );
}

function Home({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const features = [
    [icons.satellite, "Datos NASA", "Precipitación regional GPM IMERG V07 cargada por el equipo."],
    [
      icons.shield,
      "Evaluación preventiva",
      "Identifica coincidencias que requieren atención, sin confirmar contaminación.",
    ],
    [
      icons.leaf,
      "Agricultura sostenible",
      "Apoya decisiones informadas para proteger suelo, cultivo y agua.",
    ],
  ] as const;
  return (
    <>
      <section className="hero page-width">
        <div className="hero-copy">
          <div className="eyebrow">
            <span /> Agricultura + ciencia de datos
          </div>
          <h1>
            Protegemos el agua
            <br />
            desde la <em>agricultura</em>
          </h1>
          <p>
            Integramos registros agrícolas con datos de precipitación de NASA para identificar
            condiciones que podrían favorecer el transporte de nutrientes hacia aguas subterráneas.
          </p>
          <div className="button-row">
            <button className="button primary" onClick={() => onNavigate("mapa")}>
              Comenzar evaluación <Icon>{icons.arrow}</Icon>
            </button>
            <button className="button secondary" onClick={() => onNavigate("registro")}>
              Registrar aplicación
            </button>
          </div>
          <div className="pilot-label">
            <Icon>{icons.pin}</Icon>
            <span>
              <small>Área piloto</small>El Encinar, Guanacaste, Costa Rica · Cultivo: soya
            </span>
          </div>
        </div>
        <div className="hero-visual" aria-label="Vista previa referencial del área piloto">
          <div className="visual-grid" />
          <div className="water-rings ring-one" />
          <div className="water-rings ring-two" />
          <div className="field-card">
            <span className="field-icon">
              <Icon>{icons.leaf}</Icon>
            </span>
            <div>
              <small>Parcela de demostración</small>
              <strong>El Encinar</strong>
              <p>Ubicación referencial · Soya</p>
            </div>
          </div>
          <div className="rain-card">
            <Icon>{icons.water}</Icon>
            <div>
              <small>Datos ambientales</small>
              <strong>GPM IMERG V07</strong>
              <p>Escala regional aproximada</p>
            </div>
          </div>
          <div className="visual-caption">
            <span /> Recorrido demostrativo
          </div>
        </div>
      </section>
      <section className="feature-strip page-width">
        {features.map(([icon, title, description]) => (
          <article key={title}>
            <Icon>{icon}</Icon>
            <div>
              <h2>{title}</h2>
              <p>{description}</p>
            </div>
          </article>
        ))}
      </section>
    </>
  );
}

type MapProps = {
  record: RecordData;
  parcelVertices: Coordinate[];
  setParcelVertices: (vertices: Coordinate[]) => void;
  parcelClosed: boolean;
  setParcelClosed: (closed: boolean) => void;
  dataMode: DataMode;
  setDataMode: (mode: DataMode) => void;
  rainData: RainData | null;
  fileError: string;
  onFile: (event: ChangeEvent<HTMLInputElement>) => void;
  config: Config;
  setConfig: (config: Config) => void;
  demoScenario: "a" | "b";
  setDemoScenario: (scenario: "a" | "b") => void;
  rainPeriod: string;
  onNavigate: (page: Page) => void;
};

function MapPage(props: MapProps) {
  const {
    record,
    parcelVertices,
    setParcelVertices,
    parcelClosed,
    setParcelClosed,
    dataMode,
    setDataMode,
    rainData,
    fileError,
    onFile,
    config,
    setConfig,
    demoScenario,
    setDemoScenario,
    rainPeriod,
    onNavigate,
  } = props;
  const georeferencedRain = useMemo(
    () =>
      (rainData?.rows || [])
        .filter(
          (row) =>
            row.latitude !== undefined &&
            row.longitude !== undefined &&
            Number.isFinite(Number(row.latitude)) &&
            Number.isFinite(Number(row.longitude)) &&
            Number(row.latitude) >= -90 &&
            Number(row.latitude) <= 90 &&
            Number(row.longitude) >= -180 &&
            Number(row.longitude) <= 180,
        )
        .map((row) => ({
          coordinate: [Number(row.longitude), Number(row.latitude)] as Coordinate,
          precipitation: row.precipitation,
          date: row.date,
        })),
    [rainData],
  );
  return (
    <div className="page-width page-section">
      <PageHeading
        eyebrow="Exploración del área"
        title="Mapa y datos ambientales"
        text="Ubica la parcela y prepara la precipitación que utilizará la evaluación."
      />
      <div className="map-layout">
        <div>
          <ParcelBoundary
            vertices={parcelVertices}
            closed={parcelClosed}
            rainPoints={georeferencedRain}
            onVerticesChange={setParcelVertices}
            onClosedChange={setParcelClosed}
          />
          <div className="map-note">
            <Icon>{icons.warning}</Icon>
            <span>
              GPM IMERG tiene una escala aproximada de 0,1° (alrededor de 10 km). Representa
              precipitación regional, no una medición exacta de la parcela.
            </span>
          </div>
        </div>

        <aside className="data-panel">
          <div className="parcel-summary">
            <span className="section-icon">
              <Icon>{icons.leaf}</Icon>
            </span>
            <div>
              <small>Parcela de demostración</small>
              <h2>{record.name}</h2>
              <p>{record.location}</p>
            </div>
            <span className="crop-tag">Soya</span>
          </div>
          <div className="coordinate-box geometry-connection">
            <div className="subheading">
              <h3>Geometría de la parcela</h3>
              <span>GeoJSON WGS84</span>
            </div>
            <p>
              {parcelGeoJson(parcelVertices) && parcelClosed
                ? `${parcelVertices.length} vértices guardados para el mapa y la evaluación ambiental.`
                : "Aún no existe una parcela delimitada. Usa las herramientas del mapa."}
            </p>
          </div>
          <div className="mode-section">
            <div className="subheading">
              <h3>Datos de precipitación</h3>
              <span>NASA GPM IMERG V07</span>
            </div>
            <div className="segmented">
              <button
                className={dataMode === "real" ? "selected" : ""}
                onClick={() => setDataMode("real")}
              >
                Datos reales
              </button>
              <button
                className={dataMode === "demo" ? "selected" : ""}
                onClick={() => setDataMode("demo")}
              >
                Modo demostración
              </button>
            </div>
            {dataMode === "real" ? (
              <div className="upload-area">
                <input id="rain-file" type="file" accept=".csv,.json" onChange={onFile} />
                <label htmlFor="rain-file">
                  <Icon>{icons.upload}</Icon>
                  <strong>Cargar CSV o JSON preparado</strong>
                  <span>CSV: date, precipitation_mm</span>
                </label>
                {fileError && (
                  <div className="inline-error" role="alert">
                    {fileError}
                  </div>
                )}
                {rainData && <RainMeta rainData={rainData} period={rainPeriod} />}
                {!rainData && !fileError && (
                  <p className="empty-data">Información de precipitación no disponible.</p>
                )}
              </div>
            ) : (
              <div className="demo-data">
                <strong>DEMOSTRATIVOS / NO SON OBSERVACIONES NASA</strong>
                <p>Selecciona expresamente el escenario sintético para el recorrido.</p>
                <div className="mini-options">
                  <button
                    className={demoScenario === "a" ? "active" : ""}
                    onClick={() => setDemoScenario("a")}
                  >
                    Lluvia relevante
                  </button>
                  <button
                    className={demoScenario === "b" ? "active" : ""}
                    onClick={() => setDemoScenario("b")}
                  >
                    Lluvia poco relevante
                  </button>
                </div>
              </div>
            )}
          </div>
          <ConfigPanel config={config} setConfig={setConfig} />
          <div className="map-actions">
            <button className="button primary" onClick={() => onNavigate("registro")}>
              Registrar aplicación <Icon>{icons.arrow}</Icon>
            </button>
            <button className="text-button" onClick={() => onNavigate("inicio")}>
              Volver al inicio
            </button>
          </div>
        </aside>
      </div>
    </div>
  );
}

function RainMeta({ rainData, period }: { rainData: RainData; period: string }) {
  return (
    <div className="rain-meta">
      <div className="valid-row">
        <Icon>{icons.check}</Icon>
        <strong>Archivo validado</strong>
      </div>
      <dl>
        <div>
          <dt>Archivo</dt>
          <dd>{rainData.fileName}</dd>
        </div>
        <div>
          <dt>Periodo</dt>
          <dd>{period}</dd>
        </div>
        <div>
          <dt>Unidad</dt>
          <dd>{rainData.unit}</dd>
        </div>
        <div>
          <dt>Fuente</dt>
          <dd>{rainData.source}</dd>
        </div>
        <div>
          <dt>Producto</dt>
          <dd>{rainData.product}</dd>
        </div>
        <div>
          <dt>Resolución</dt>
          <dd>{rainData.resolution}</dd>
        </div>
      </dl>
      {(rainData.source.includes("no indicada") ||
        rainData.product.includes("no indicado") ||
        rainData.resolution.includes("no indicada")) && (
        <p className="metadata-warning">
          Faltan metadatos en el archivo. Complétalos en el archivo antes de presentar estos datos
          como observaciones NASA.
        </p>
      )}
    </div>
  );
}

function ConfigPanel({
  config,
  setConfig,
}: {
  config: Config;
  setConfig: (config: Config) => void;
}) {
  const update = (key: keyof Config, value: string | boolean) =>
    setConfig({ ...config, [key]: value });
  return (
    <details className="config-panel">
      <summary>
        Configurar reglas de evaluación <span>Requerido para datos reales</span>
      </summary>
      <p>Define criterios para esta demo. No se aplican umbrales agronómicos universales.</p>
      <div className="field-pair">
        <label>
          Ventana reciente (días)
          <input
            type="number"
            min="1"
            value={config.recentDays}
            onChange={(e) => update("recentDays", e.target.value)}
            placeholder="Configurar"
          />
        </label>
        <label>
          Lluvia relevante (mm)
          <input
            type="number"
            min="0"
            value={config.relevantRain}
            onChange={(e) => update("relevantRain", e.target.value)}
            placeholder="Configurar"
          />
        </label>
      </div>
      <label className="check-label">
        <input
          type="checkbox"
          checked={config.useIntermediate}
          onChange={(e) => update("useIntermediate", e.target.checked)}
        />{" "}
        Usar categoría intermedia (T = 1)
      </label>
      {config.useIntermediate && (
        <label>
          Desde qué valor es intermedia (mm)
          <input
            type="number"
            min="0"
            value={config.intermediateRain}
            onChange={(e) => update("intermediateRain", e.target.value)}
            placeholder="Configurar"
          />
        </label>
      )}
      <div className="field-pair">
        <label>
          Máximo categoría baja
          <input
            type="number"
            min="0"
            max="100"
            value={config.lowMax}
            onChange={(e) => update("lowMax", e.target.value)}
            placeholder="Configurar"
          />
        </label>
        <label>
          Máximo categoría moderada
          <input
            type="number"
            min="0"
            max="100"
            value={config.moderateMax}
            onChange={(e) => update("moderateMax", e.target.value)}
            placeholder="Configurar"
          />
        </label>
      </div>
    </details>
  );
}

type RegisterProps = {
  record: RecordData;
  setRecord: (record: RecordData) => void;
  errors: Record<string, string>;
  savedRecord: RecordData | null;
  savedNotice: boolean;
  parcelVertices: Coordinate[];
  parcelClosed: boolean;
  onSave: () => void;
  onEvaluate: () => void;
  onNavigate: (page: Page) => void;
};

function RegisterPage({
  record,
  setRecord,
  errors,
  savedRecord,
  savedNotice,
  parcelVertices,
  parcelClosed,
  onSave,
  onEvaluate,
  onNavigate,
}: RegisterProps) {
  const update = (key: keyof RecordData, value: string) => setRecord({ ...record, [key]: value });
  const submit = (event: FormEvent) => event.preventDefault();
  const parcelMetrics = parcelClosed ? getParcelMetrics(parcelVertices) : null;
  return (
    <div className="page-width page-section narrow-page">
      <PageHeading
        eyebrow="Registro agrícola"
        title="Aplicación de fertilizante"
        text="Registra únicamente la información esencial para evaluar las condiciones de esta demostración."
      />
      <div className="form-layout">
        <form className="record-form" onSubmit={submit} noValidate>
          <div className="form-section-title">
            <span>01</span>
            <div>
              <h2>Parcela y cultivo</h2>
              <p>Una sola parcela para el caso piloto.</p>
            </div>
          </div>
          <div className="form-grid">
            <Field label="Nombre de parcela" required error={errors.name}>
              <input
                value={record.name}
                onChange={(e) => update("name", e.target.value)}
                aria-invalid={Boolean(errors.name)}
              />
            </Field>
            <Field label="Cultivo" required hint="Fijo para esta demostración">
              <input value={record.crop} readOnly />
            </Field>
            <Field label="Ubicación" wide hint="Caso piloto">
              <input value={record.location} readOnly />
            </Field>
            <div className="wide parcel-form-summary">
              <div className="field-label">
                Delimitación de la parcela <span>GeoJSON WGS84</span>
              </div>
              <div className={parcelMetrics ? "parcel-linked ready" : "parcel-linked"}>
                <div>
                  <strong>{parcelMetrics ? "Parcela delimitada" : "Parcela sin delimitar"}</strong>
                  <p>
                    {parcelMetrics
                      ? `${parcelVertices.length} vértices · ${new Intl.NumberFormat("es-CR", { maximumFractionDigits: 4 }).format(parcelMetrics.areaHectares)} ha`
                      : "Puedes continuar con el registro, pero la geometría no estará disponible para el análisis espacial."}
                  </p>
                </div>
                <button type="button" className="text-button" onClick={() => onNavigate("mapa")}>
                  {parcelMetrics ? "Editar límites" : "Delimitar en el mapa"}
                </button>
              </div>
            </div>
          </div>
          <div className="form-divider" />
          <div className="form-section-title">
            <span>02</span>
            <div>
              <h2>Datos de la aplicación</h2>
              <p>La dosis es opcional y no bloquea la evaluación.</p>
            </div>
          </div>
          <div className="form-grid">
            <Field label="Tipo de fertilizante nitrogenado" required error={errors.fertilizer} wide>
              <input
                value={record.fertilizer}
                onChange={(e) => update("fertilizer", e.target.value)}
                placeholder="Ej. nombre indicado en el registro de campo"
                aria-invalid={Boolean(errors.fertilizer)}
              />
            </Field>
            <Field label="Fecha de aplicación" required error={errors.applicationDate}>
              <input
                type="date"
                value={record.applicationDate}
                onChange={(e) => update("applicationDate", e.target.value)}
                aria-invalid={Boolean(errors.applicationDate)}
              />
            </Field>
            <div className="field">
              <div className="field-label">
                Dosis aplicada <span>Opcional</span>
              </div>
              <div className="dose-row">
                <input
                  type="number"
                  min="0"
                  value={record.dose}
                  onChange={(e) => update("dose", e.target.value)}
                  placeholder="Cantidad"
                />
                <input
                  value={record.doseUnit}
                  onChange={(e) => update("doseUnit", e.target.value)}
                  placeholder="Unidad indicada"
                  aria-label="Unidad de dosis"
                />
              </div>
            </div>
          </div>
          <div className="form-actions">
            <button type="button" className="button secondary" onClick={onSave}>
              Guardar registro
            </button>
            <button type="button" className="button primary" onClick={onEvaluate}>
              Evaluar condiciones <Icon>{icons.arrow}</Icon>
            </button>
            <button type="button" className="text-button" onClick={() => onNavigate("mapa")}>
              Volver al mapa
            </button>
          </div>
        </form>
        <aside className="record-aside">
          <div className="aside-heading">
            <Icon>{icons.leaf}</Icon>
            <div>
              <small>Resumen</small>
              <h2>Registro actual</h2>
            </div>
          </div>
          <dl>
            <div>
              <dt>Parcela</dt>
              <dd>{record.name || "Sin dato"}</dd>
            </div>
            <div>
              <dt>Cultivo</dt>
              <dd>{record.crop}</dd>
            </div>
            <div>
              <dt>Fertilizante</dt>
              <dd>{record.fertilizer || "Pendiente"}</dd>
            </div>
            <div>
              <dt>Fecha</dt>
              <dd>{formatDate(record.applicationDate) || "Pendiente"}</dd>
            </div>
            <div>
              <dt>Dosis</dt>
              <dd>
                {record.dose
                  ? `${record.dose} ${record.doseUnit || "(unidad sin indicar)"}`
                  : "No indicada (opcional)"}
              </dd>
            </div>
            <div>
              <dt>Geometría</dt>
              <dd>
                {parcelMetrics
                  ? `${parcelVertices.length} vértices · ${new Intl.NumberFormat("es-CR", { maximumFractionDigits: 2 }).format(parcelMetrics.areaSquareMeters)} m²`
                  : "No delimitada"}
              </dd>
            </div>
          </dl>
          {savedNotice && savedRecord && (
            <div className="save-confirmation">
              <Icon>{icons.check}</Icon>
              <span>
                <strong>Registro guardado</strong>Se conservará durante este recorrido.
              </span>
            </div>
          )}
          <p className="aside-note">
            Los campos marcados con * son obligatorios. Guardar no envía información a un servidor.
          </p>
        </aside>
      </div>
    </div>
  );
}

function Field({
  label,
  required,
  hint,
  error,
  wide,
  children,
}: {
  label: string;
  required?: boolean;
  hint?: string;
  error?: string;
  wide?: boolean;
  children: ReactNode;
}) {
  return (
    <label className={`field ${wide ? "wide" : ""}`}>
      <span className="field-label">
        {label} {required && <b>*</b>} {hint && <em>{hint}</em>}
      </span>
      {children}
      {error && <span className="error-text">{error}</span>}
    </label>
  );
}

type Evaluation = {
  complete: boolean;
  missing: string[];
  s?: number;
  t?: number;
  score?: number;
  category?: string;
  rainDescription?: string;
  recent?: boolean;
  relevantRain?: boolean;
  sourceLabel: string;
  period: string;
};

type ResultsProps = {
  record: RecordData;
  hasSavedRecord: boolean;
  dataMode: DataMode;
  rainData: RainData | null;
  config: Config;
  resultView: ResultView;
  setResultView: (view: ResultView) => void;
  demoScenario: "a" | "b";
  rainPeriod: string;
  onNavigate: (page: Page) => void;
};

function ResultsPage(props: ResultsProps) {
  const {
    record,
    hasSavedRecord,
    dataMode,
    rainData,
    config,
    resultView,
    setResultView,
    demoScenario,
    rainPeriod,
    onNavigate,
  } = props;
  const evaluation = useMemo<Evaluation>(() => {
    if (
      resultView === "a" ||
      (resultView === "actual" && dataMode === "demo" && demoScenario === "a")
    ) {
      return {
        complete: true,
        missing: [],
        s: 2,
        t: 2,
        score: 100,
        category: "Elevado",
        recent: true,
        relevantRain: true,
        rainDescription: "Precipitación relevante en el escenario sintético.",
        sourceLabel: "Escenario demostrativo",
        period: "Periodo sintético posterior a la aplicación",
      };
    }
    if (
      resultView === "b" ||
      (resultView === "actual" && dataMode === "demo" && demoScenario === "b")
    ) {
      return {
        complete: true,
        missing: [],
        s: 2,
        t: 0,
        score: 50,
        category: "Moderado",
        recent: true,
        relevantRain: false,
        rainDescription: "No se identificó lluvia relevante en el periodo del ejemplo.",
        sourceLabel: "Escenario demostrativo",
        period: "Periodo sintético posterior a la aplicación",
      };
    }
    if (resultView === "incompleto") {
      return {
        complete: false,
        missing: ["Fecha de aplicación", "Precipitación del periodo posterior"],
        sourceLabel: "Sin fuente utilizable",
        period: "No disponible",
      };
    }
    const missing: string[] = [];
    if (!hasSavedRecord || !record.applicationDate) missing.push("Fecha de aplicación guardada");
    if (!rainData) missing.push("Precipitación para el periodo posterior a la aplicación");
    if (!config.recentDays) missing.push("Ventana de aplicación reciente");
    if (!config.relevantRain) missing.push("Umbral de lluvia relevante");
    if (!config.lowMax || !config.moderateMax) missing.push("Límites de categorías demostrativas");
    if (config.useIntermediate && !config.intermediateRain)
      missing.push("Umbral de lluvia intermedia");
    if (
      rainData &&
      (rainData.source.includes("no indicada") ||
        rainData.product.includes("no indicado") ||
        rainData.resolution.includes("no indicada"))
    ) {
      missing.push("Metadatos completos de fuente, producto y resolución");
    }
    if (missing.length)
      return {
        complete: false,
        missing,
        sourceLabel: rainData?.source || "Sin fuente utilizable",
        period: rainPeriod,
      };

    const application = new Date(`${record.applicationDate}T12:00:00`);
    const periodRows = rainData!.rows.filter(
      (row) => new Date(`${row.date}T12:00:00`) >= application,
    );
    if (!periodRows.length)
      return {
        complete: false,
        missing: ["Precipitación posterior a la fecha de aplicación"],
        sourceLabel: rainData!.source,
        period: "Información de precipitación no disponible",
      };
    const latestRainDate = new Date(
      `${periodRows
        .map((row) => row.date)
        .sort()
        .at(-1)}T12:00:00`,
    );
    const elapsedDays = Math.floor((latestRainDate.getTime() - application.getTime()) / 86400000);
    const recent = elapsedDays <= Number(config.recentDays);
    const totalRain = periodRows.reduce((total, row) => total + row.precipitation, 0);
    let t = totalRain >= Number(config.relevantRain) ? 2 : 0;
    if (
      config.useIntermediate &&
      totalRain >= Number(config.intermediateRain) &&
      totalRain < Number(config.relevantRain)
    )
      t = 1;
    const s = recent ? 2 : 0;
    const score = (100 * (s + t)) / 4;
    const category =
      score <= Number(config.lowMax)
        ? "Bajo"
        : score <= Number(config.moderateMax)
          ? "Moderado"
          : "Elevado";
    return {
      complete: true,
      missing: [],
      s,
      t,
      score,
      category,
      recent,
      relevantRain: t === 2,
      rainDescription: `${totalRain} mm acumulados en ${periodRows.length} registro(s) posteriores a la aplicación.`,
      sourceLabel: `${rainData!.source} · ${rainData!.product}`,
      period: rainPeriod,
    };
  }, [
    config,
    dataMode,
    demoScenario,
    hasSavedRecord,
    rainData,
    rainPeriod,
    record.applicationDate,
    resultView,
  ]);

  const isSynthetic =
    resultView === "a" ||
    resultView === "b" ||
    resultView === "incompleto" ||
    (resultView === "actual" && dataMode === "demo");
  return (
    <div className="page-width page-section results-page">
      <PageHeading
        eyebrow="Resultados"
        title="Evaluación de condiciones"
        text="Lectura preventiva basada en el registro agrícola y la precipitación disponible."
      />
      <section className="scenario-switcher">
        <div>
          <small>Vista de resultados</small>
          <strong>Compara cómo cambia el indicador</strong>
        </div>
        <div className="scenario-buttons" role="group" aria-label="Seleccionar vista de resultados">
          <button
            className={resultView === "actual" ? "active" : ""}
            onClick={() => setResultView("actual")}
          >
            Evaluación actual
          </button>
          <button className={resultView === "a" ? "active" : ""} onClick={() => setResultView("a")}>
            Escenario A
          </button>
          <button className={resultView === "b" ? "active" : ""} onClick={() => setResultView("b")}>
            Escenario B
          </button>
          <button
            className={resultView === "incompleto" ? "active" : ""}
            onClick={() => setResultView("incompleto")}
          >
            Datos incompletos
          </button>
        </div>
      </section>
      {isSynthetic && (
        <div className="demo-banner">
          <Icon>{icons.warning}</Icon>
          <strong>Escenario demostrativo; no representa una observación real de NASA.</strong>
        </div>
      )}
      {evaluation.complete ? (
        <>
          <div className="results-grid">
            <section className={`score-card score-${evaluation.category?.toLowerCase()}`}>
              <div className="score-top">
                <span>Indicador demostrativo</span>
                <span className="category-pill">{evaluation.category}</span>
              </div>
              <div
                className="gauge"
                style={{ "--score": `${evaluation.score}%` } as React.CSSProperties}
              >
                <div>
                  <strong>{evaluation.score}</strong>
                  <span>/100</span>
                </div>
              </div>
              <p>No es una probabilidad de contaminación ni un modelo validado.</p>
            </section>
            <section className="factor-card">
              <div className="factor">
                <span className="factor-value">S = {evaluation.s}</span>
                <div>
                  <strong>Presión de la fuente</strong>
                  <p>
                    {evaluation.recent
                      ? "Existe una aplicación dentro de la ventana reciente usada en esta vista."
                      : "No hay una aplicación dentro de la ventana reciente configurada."}
                  </p>
                </div>
              </div>
              <div className="factor">
                <span className="factor-value blue">T = {evaluation.t}</span>
                <div>
                  <strong>Condición de transporte</strong>
                  <p>{evaluation.rainDescription}</p>
                </div>
              </div>
              <div className="formula-line">
                R = 100 × (S + T) / 4 <span>Configuración demostrativa</span>
              </div>
            </section>
            <section className="summary-card">
              <div className="card-title">
                <Icon>{icons.leaf}</Icon>
                <h2>Resumen analizado</h2>
              </div>
              <dl>
                <div>
                  <dt>Parcela</dt>
                  <dd>{record.name}</dd>
                </div>
                <div>
                  <dt>Cultivo</dt>
                  <dd>{record.crop}</dd>
                </div>
                <div>
                  <dt>Aplicación</dt>
                  <dd>
                    {formatDate(record.applicationDate) ||
                      (isSynthetic ? "Reciente (sintética)" : "Sin fecha")}
                  </dd>
                </div>
                <div>
                  <dt>Periodo de lluvia</dt>
                  <dd>{evaluation.period}</dd>
                </div>
                <div>
                  <dt>Fuente</dt>
                  <dd>{evaluation.sourceLabel}</dd>
                </div>
              </dl>
              <div className="confidence">
                <span>Confianza limitada</span>
                <p>
                  No se dispone de una capa confiable de acuíferos ni de datos complementarios de
                  suelo o agua.
                </p>
              </div>
            </section>
          </div>
          <section
            className={`alert-panel ${evaluation.relevantRain && evaluation.s === 2 ? "warning" : "calm"}`}
          >
            <Icon>
              {evaluation.relevantRain && evaluation.s === 2 ? icons.warning : icons.check}
            </Icon>
            <div>
              <small>
                {evaluation.relevantRain && evaluation.s === 2
                  ? "Alerta preventiva"
                  : "Condición no activada"}
              </small>
              <h2>
                {evaluation.relevantRain && evaluation.s === 2
                  ? "Coinciden aplicación reciente y precipitación relevante"
                  : "No se identificó lluvia relevante en el periodo"}
              </h2>
              <p>
                {evaluation.relevantRain && evaluation.s === 2
                  ? "Estas condiciones pueden favorecer el movimiento de nutrientes en el suelo. Esto no confirma que hayan alcanzado el agua subterránea."
                  : "La condición de transporte por lluvia relevante no se activó en esta vista. Esto no equivale a confirmar ausencia de transporte."}
              </p>
            </div>
          </section>
          <section className="recommendation">
            <span className="recommend-icon">
              <Icon>{icons.leaf}</Icon>
            </span>
            <div>
              <small>Recomendación general</small>
              <h2>Planificar con el clima en mente</h2>
              <p>
                Revisar el momento de futuras aplicaciones, evitar aplicaciones antes de lluvias
                importantes cuando sea agronómicamente posible y evitar excesos de riego. Cualquier
                ajuste debe seguir las necesidades del cultivo y asesoría técnica.
              </p>
            </div>
          </section>
        </>
      ) : (
        <section className="incomplete-state">
          <span className="incomplete-icon">
            <Icon>{icons.warning}</Icon>
          </span>
          <small>Resultado no calculado</small>
          <h2>Evaluación incompleta</h2>
          <p>No se sustituirán datos ausentes por cero. Para calcular el indicador falta:</p>
          <ul>
            {evaluation.missing.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
          <div className="button-row">
            <button className="button primary" onClick={() => onNavigate("registro")}>
              Volver al registro
            </button>
            <button className="button secondary" onClick={() => onNavigate("mapa")}>
              Revisar datos ambientales
            </button>
          </div>
        </section>
      )}
      <div className="results-actions">
        <button className="text-button" onClick={() => onNavigate("registro")}>
          Editar registro
        </button>
        <button className="text-button" onClick={() => onNavigate("mapa")}>
          Revisar mapa y datos
        </button>
      </div>
    </div>
  );
}

function PageHeading({ eyebrow, title, text }: { eyebrow: string; title: string; text: string }) {
  return (
    <div className="page-heading">
      <span>{eyebrow}</span>
      <h1>{title}</h1>
      <p>{text}</p>
    </div>
  );
}

function formatDate(value: string) {
  if (!value) return "";
  const date = new Date(`${value}T12:00:00`);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat("es-CR", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(date);
}

export default App;
