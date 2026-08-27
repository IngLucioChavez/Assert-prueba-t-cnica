import { LIMITE_PAGINA } from '../constants';
import type { EstadoTransaccion, FiltroEstado, RespuestaMockFetch, Transaccion } from '../types/transaccion';

const ESTADOS: EstadoTransaccion[] = ['pendiente', 'aprobado', 'rechazado'];

const CLIENTES = [
  'Banco Aurora', 'Financiera del Norte', 'Grupo Meridiano', 'Credito Facil SA',
  'Institucion Vallarta', 'Fondo Esperanza', 'Banca Popular MX', 'Prestamos Union',
  'Capital Sierra', 'Financiera Rio Bravo',
];

function generarDataset(): Transaccion[] {
  const total = 137;
  const datos: Transaccion[] = [];
  let semilla = 42;
  const siguiente = () => {
    semilla = (semilla * 1103515245 + 12345) % 2147483648;
    return semilla / 2147483648;
  };

  for (let i = 1; i <= total; i += 1) {
    const diasAtras = Math.floor(siguiente() * 90);
    const fecha = new Date();
    fecha.setDate(fecha.getDate() - diasAtras);

    datos.push({
      id: i,
      cliente: CLIENTES[Math.floor(siguiente() * CLIENTES.length)],
      monto: Math.round((siguiente() * 48000 + 200 - siguiente() * 4000) * 100) / 100,
      estado: ESTADOS[Math.floor(siguiente() * ESTADOS.length)],
      fecha: fecha.toISOString(),
    });
  }
  return datos;
}

const DATASET = generarDataset();

function retrasoAleatorio(): Promise<void> {
  const ms = 350 + Math.random() * 450;
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function mockFetch(page = 1, estado: FiltroEstado = 'todas'): Promise<RespuestaMockFetch> {
  await retrasoAleatorio();

  if (Math.random() < 1 / 12) {
    throw new Error('Fallo simulado de red al consultar transacciones.');
  }

  const filtradas = estado === 'todas' ? DATASET : DATASET.filter((t) => t.estado === estado);

  const total = filtradas.length;
  const pages = Math.max(Math.ceil(total / LIMITE_PAGINA), 1);
  const paginaValida = Math.min(Math.max(Math.trunc(page) || 1, 1), pages);
  const inicio = (paginaValida - 1) * LIMITE_PAGINA;
  const data = filtradas.slice(inicio, inicio + LIMITE_PAGINA);

  return { data, total, pages };
}
