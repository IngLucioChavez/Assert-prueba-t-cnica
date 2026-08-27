export type EstadoTransaccion = 'pendiente' | 'aprobado' | 'rechazado';

export type FiltroEstado = EstadoTransaccion | 'todas';

export interface Transaccion {
  id: number;
  cliente: string;
  monto: number;
  estado: EstadoTransaccion;
  fecha: string; // ISO 8601
}

export interface RespuestaMockFetch {
  data: Transaccion[];
  total: number;
  pages: number;
}
