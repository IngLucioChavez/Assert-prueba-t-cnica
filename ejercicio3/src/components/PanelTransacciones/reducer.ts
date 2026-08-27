import type { FiltroEstado, Transaccion } from '../../types/transaccion';

//estructura del estado
export interface PanelState {
  datos: Transaccion[];
  pagina: number;
  totalPaginas: number;
  filtro: FiltroEstado;
  cargando: boolean;
  error: string | null;
  intentoId: number;
}

//definiendo estado inicial con base a estructura de estado
export const initialState: PanelState = {
  datos: [],
  pagina: 1,
  totalPaginas: 1,
  filtro: 'todas',
  cargando: true,
  error: null,
  intentoId: 0,
};

// tipos de estados aceptados
export type PanelAction =
  | { type: 'FETCH_INICIO' }
  | { type: 'FETCH_EXITO'; payload: { datos: Transaccion[]; totalPaginas: number } }
  | { type: 'FETCH_ERROR'; payload: string }
  | { type: 'CAMBIAR_FILTRO'; payload: FiltroEstado }
  | { type: 'CAMBIAR_PAGINA'; payload: number }
  | { type: 'REINTENTAR' };

// función para payload
export function panelReducer(state: PanelState, action: PanelAction): PanelState {
  switch (action.type) {
    // estado inicial 
    case 'FETCH_INICIO':
      return { ...state, cargando: true, error: null };
    //cuando la carga de la data es exitosa
    case 'FETCH_EXITO':
      return {
        ...state,
        cargando: false,
        error: null,
        datos: action.payload.datos,
        totalPaginas: Math.max(action.payload.totalPaginas, 1),
      };
    // para error al recibir la data
    case 'FETCH_ERROR':
      return { ...state, cargando: false, error: action.payload, datos: [] };
    // para cambiar filtrado de la data
    case 'CAMBIAR_FILTRO':
      return { ...state, filtro: action.payload, pagina: 1 };
    // para cambiar de página 
    case 'CAMBIAR_PAGINA':
      return { ...state, pagina: action.payload };
    // para reintento de obtener data
    case 'REINTENTAR':
      return { ...state, intentoId: state.intentoId + 1 };

    default:
      return state;
  }
}
