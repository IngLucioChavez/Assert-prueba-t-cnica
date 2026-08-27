import { LIMITE_PAGINA } from '../constants';
import type { EstadoTransaccion, FiltroEstado, RespuestaMockFetch, Transaccion } from '../types/transaccion';

// tipos de estado en relación al type declarado
const ESTADOS: EstadoTransaccion[] = ['pendiente', 'aprobado', 'rechazado'];

// arreglo de clientes mock
const CLIENTES = [
  'Lucio Francisco Chávez García',
  'Carlos Alam Chávez García',
  'Ma Guadalupe García Delgado',
  'Ma Isabel García Delgado',
  'Juan Pablo Silva Gutiérres',
  'Juan Alberto Mendoza Pérez',
  'Paola Ferreira Chávez',
  'Rut López Silva',
  'Eugenio Mendez López',
];

//funcion que genera arreglo de datos mock
function generarDataset(): Transaccion[] {
  const total = 123;
  const datos: Transaccion[] = [];

  // funcion que retorna número aleatorio entre dos números
  const siguiente = (min: number, max: number) => {
    return Math.floor(Math.random() * (max - min + 1));
  };

  for (let i = 1; i <= total; i += 1) {
    const diasAtras = Math.floor(siguiente(1, 10) * 90);
    const fecha = new Date();
    fecha.setDate(fecha.getDate() - diasAtras);

    datos.push({
      id: i,
      cliente: CLIENTES[siguiente(0, 8)],
      monto: Math.round((siguiente(100, 1000) * 48000 + 200 - siguiente(100, 1000) * 4000) * 100) / 100,
      estado: ESTADOS[siguiente(0, 2)],
      fecha: fecha.toISOString(),
    });
  }
  return datos;
}
// se define la data
const DATASET = generarDataset();

// función que regresa promesa simula retraso en ms
function retrasoAleatorio(): Promise<void> {
  const ms = 350 + Math.random() * 450;
  return new Promise((resolve) => setTimeout(resolve, ms));
}

//función async que generá el fetch del mock a través de pagina y filtro de estado
//retorna promesa con estructura de RepuestaMockFetch
export async function mockFetch(page = 1, estado: FiltroEstado = 'todas'): Promise<RespuestaMockFetch> {
  await retrasoAleatorio();

  // simulación de fallo de conexión
  if (Math.random() < 1 / 12) {
    throw new Error('Fallo simulado de red al consultar transacciones.');
  }

  // si es todas se retorna el arreglo completo sino se filtra por el estado seleccionado
  const filtradas = estado === 'todas' ? DATASET : DATASET.filter((t) => t.estado === estado);

  const total = filtradas.length;
  // calculo de páginas totales
  const pages = (total % LIMITE_PAGINA == 0) ? (total / LIMITE_PAGINA) : Math.ceil(total / LIMITE_PAGINA);
  // validando número de página
  const paginaValida = (page > 0 && page <= pages) ? page : pages;
  // definidiendo inicio de chunck respecto a página
  const inicio = (paginaValida - 1) * LIMITE_PAGINA;
  // filtrado de la data
  const data = filtradas.slice(inicio, inicio + LIMITE_PAGINA);

  return { data, total, pages };
}
