import { useEffect, useReducer, useRef } from 'react';
import { mockFetch } from '../../api/mockApi';
import { LIMITE_PAGINA } from '../../constants';
import type { FiltroEstado } from '../../types/transaccion';
import { initialState, panelReducer } from './reducer';
import { exportarCSV } from './csvExport';
import './PanelTransacciones.css';

// filtros permitidos con valor y etiqueta 
// valor con respecto a estado del filtrado de la información
const FILTROS: { valor: FiltroEstado; etiqueta: string }[] = [
  { valor: 'todas', etiqueta: 'Todas' },
  { valor: 'pendiente', etiqueta: 'Pendiente' },
  { valor: 'aprobado', etiqueta: 'Aprobado' },
  { valor: 'rechazado', etiqueta: 'Rechazado' },
];

export default function PanelTransacciones() {
  // creando reducer con estado inicial
  const [state, dispatch] = useReducer(panelReducer, initialState);

  const controllerRef = useRef<AbortController | null>(null);

  useEffect(() => {

    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;

    //definiendo estado inicial
    dispatch({ type: 'FETCH_INICIO' });

    //promesa que retornado la data mock
    mockFetch(state.pagina, state.filtro)
      .then((respuesta) => {
        if (controller.signal.aborted) return;
        // se define estado en caso de exito
        dispatch({
          type: 'FETCH_EXITO',
          payload: { datos: respuesta.data, totalPaginas: respuesta.pages },
        });
      })
      .catch((err: unknown) => {
        if (controller.signal.aborted) return;
        const mensaje =
          err instanceof Error ? err.message : 'Error desconocido al obtener las transacciones.';
        //se define estado en caso de error
        dispatch({ type: 'FETCH_ERROR', payload: mensaje });
      });

    return () => {
      controller.abort();
    };

  }, [state.pagina, state.filtro, state.intentoId]); //useEffect se activa en primer renderizado y cuando alguna de estas opciones cambie

  const cambiarFiltro = (filtro: FiltroEstado) => {
    if (filtro === state.filtro) return;
    // definiendo estado al cambiar filtro
    dispatch({ type: 'CAMBIAR_FILTRO', payload: filtro });
  };

  const irAPaginaAnterior = () => {
    if (state.pagina <= 1) return;
    //definiendo estado al cambiar de pagina a anterior
    dispatch({ type: 'CAMBIAR_PAGINA', payload: state.pagina - 1 });
  };

  const irAPaginaSiguiente = () => {
    if (state.pagina >= state.totalPaginas) return;
    //definiendo estado al cambiar de pagina a posterior
    dispatch({ type: 'CAMBIAR_PAGINA', payload: state.pagina + 1 });
  };

  const manejarExportarCSV = () => {
    exportarCSV(state.datos);
  };

  console.log(state.datos);

  const hayDatos = state.datos.length > 0;
  //no hay resultados cuando no se esta cragando, no hay error y no hay datos
  const sinResultados = !state.cargando && !state.error && !hayDatos;

  return (
    <section className="panel-transacciones">
      <header className="panel-transacciones__header">
        <h1>Transacciones</h1>

        <div className="panel-transacciones__filtros" role="group" aria-label="Filtrar por estado">
          { //dibujando opciones para filtrado
            FILTROS.map(({ valor, etiqueta }) => (
              <button
                key={valor}
                type="button"
                className={valor === state.filtro ? 'filtro filtro--activo' : 'filtro'}
                onClick={() => cambiarFiltro(valor)}
                aria-pressed={valor === state.filtro}
              >
                {etiqueta}
              </button>
            ))}
        </div>

        <button
          type="button"
          className="boton-exportar"
          onClick={manejarExportarCSV}
          disabled={!hayDatos}
          title={hayDatos ? undefined : 'No hay registros visibles para exportar'}
        >
          Exportar CSV
        </button>
      </header>

      {state.error && (
        <div role="alert" className="panel-transacciones__error">
          <p>No se pudieron cargar las transacciones: {state.error}</p>
          <button type="button" onClick={() => dispatch({ type: 'REINTENTAR' })}>
            Reintentar
          </button>
        </div>
      )}

      <div className="panel-transacciones__tabla-contenedor">
        {state.cargando ? (
          <div className="panel-transacciones__cargando" role="status">
            Cargando transacciones…
          </div>
        ) : (
          <table className="tabla-transacciones">
            <thead>
              <tr>
                <th>ID</th>
                <th>Cliente</th>
                <th>Monto</th>
                <th>Estado</th>
                <th>Fecha</th>
              </tr>
            </thead>
            <tbody>
              {sinResultados ? (
                <tr>
                  <td colSpan={5} className="tabla-transacciones__vacio">
                    No hay transacciones para este filtro.
                  </td>
                </tr>
              ) : (
                state.datos.map((t) => (
                  <tr key={t.id}>
                    <td>{t.id}</td>
                    <td>{t.cliente}</td>
                    <td>{formatearMonto(t.monto)}</td>
                    <td>
                      <span className={`insignia insignia--${t.estado}`}>{t.estado}</span>
                    </td>
                    <td>{formatearFecha(t.fecha)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

      <footer className="panel-transacciones__paginacion">
        <button type="button" onClick={irAPaginaAnterior} disabled={state.pagina <= 1 || state.cargando}>
          Anterior
        </button>
        <span>
          Página {state.pagina} de {Math.max(state.totalPaginas, 1)} · {LIMITE_PAGINA} por página
        </span>
        <button
          type="button"
          onClick={irAPaginaSiguiente}
          disabled={state.pagina >= state.totalPaginas || state.cargando}
        >
          Siguiente
        </button>
      </footer>
    </section>
  );
}

// para formatear cantidades a pesos mexicanos
function formatearMonto(monto: number): string {
  return monto.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' });
}

// para formatear fecha
function formatearFecha(fechaISO: string): string {
  const fecha = new Date(fechaISO);
  const formato =
    `${fecha.getFullYear()}-` +
    `${String(fecha.getMonth() + 1).padStart(2, '0')}-` +
    `${String(fecha.getDate()).padStart(2, '0')} ` +
    `${String(fecha.getHours()).padStart(2, '0')}:` +
    `${String(fecha.getMinutes()).padStart(2, '0')}:` +
    `${String(fecha.getSeconds()).padStart(2, '0')}`;
  return formato;
}
