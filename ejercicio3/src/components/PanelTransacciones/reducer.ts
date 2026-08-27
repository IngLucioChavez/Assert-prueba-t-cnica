import type { FiltroEstado, Transaccion } from '../../types/transaccion';

export interface PanelState {
  datos: Transaccion[];
  pagina: number;
  totalPaginas: number;
  filtro: FiltroEstado;
  cargando: boolean;
  error: string | null;
  intentoId: number;
}

export const initialState: PanelState = {
  datos: [],
  pagina: 1,
  totalPaginas: 1,
  filtro: 'todas',
  cargando: true,
  error: null,
  intentoId: 0,
};

export type PanelAction =
  | { type: 'FETCH_INICIO' }
  | { type: 'FETCH_EXITO'; payload: { datos: Transaccion[]; totalPaginas: number } }
  | { type: 'FETCH_ERROR'; payload: string }
  | { type: 'CAMBIAR_FILTRO'; payload: FiltroEstado }
  | { type: 'CAMBIAR_PAGINA'; payload: number }
  | { type: 'REINTENTAR' };

export function panelReducer(state: PanelState, action: PanelAction): PanelState {
  switch (action.type) {
    case 'FETCH_INICIO':
      return { ...state, cargando: true, error: null };

    case 'FETCH_EXITO':
      return {
        ...state,
        cargando: false,
        error: null,
        datos: action.payload.datos,
        totalPaginas: Math.max(action.payload.totalPaginas, 1),
      };

    case 'FETCH_ERROR':
      return { ...state, cargando: false, error: action.payload, datos: [] };

    case 'CAMBIAR_FILTRO':
      return { ...state, filtro: action.payload, pagina: 1 };

    case 'CAMBIAR_PAGINA':
      return { ...state, pagina: action.payload };

    case 'REINTENTAR':
      return { ...state, intentoId: state.intentoId + 1 };

    default:
      return state;
  }
}
